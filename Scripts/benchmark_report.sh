#!/bin/bash
set -euo pipefail

baseline=$(git rev-parse "$1")
target=$(git rev-parse "$2")
baseline_json=".benchmarkBaselines/TOMLDecoderBenchmarks/$baseline/results.json"
target_json=".benchmarkBaselines/TOMLDecoderBenchmarks/$target/results.json"

if [ ! -f "$baseline_json" ]; then
    echo "Missing baseline: $baseline_json" >&2
    exit 1
fi

if [ ! -f "$target_json" ]; then
    echo "Missing baseline: $target_json" >&2
    exit 1
fi

python3 - "$baseline_json" "$target_json" <<'PY'
import json
import math
import sys

baseline_path = sys.argv[1]
target_path = sys.argv[2]

TIME_UNITS_DIVISOR = {
    "nanoseconds": 1,
    "microseconds": 1_000,
    "milliseconds": 1_000_000,
    "seconds": 1_000_000_000,
    "kiloseconds": 1_000_000_000_000,
    "megaseconds": 1_000_000_000_000_000,
}

TIME_UNITS_FACTOR = {
    "nanoseconds": 1_000_000_000,
    "microseconds": 1_000_000,
    "milliseconds": 1_000,
    "seconds": 1,
    "kiloseconds": 2,
    "megaseconds": 3,
}

COUNT_UNIT_LABEL = {
    "nanoseconds": "#",
    "microseconds": "K",
    "milliseconds": "M",
    "seconds": "G",
    "kiloseconds": "T",
    "megaseconds": "P",
}

TIME_UNIT_LABEL = {
    "nanoseconds": "ns",
    "microseconds": "us",
    "milliseconds": "ms",
    "seconds": "s",
    "kiloseconds": "ks",
    "megaseconds": "Ms",
}

SCALE_LABEL = {
    1: "#",
    1_000: "K",
    1_000_000: "M",
    1_000_000_000: "G",
    1_000_000_000_000: "T",
    1_000_000_000_000_000: "P",
}

USE_SCALING_FACTOR = {
    "cpuSystem",
    "cpuTotal",
    "cpuUser",
    "wallClock",
    "mallocCountLarge",
    "mallocCountSmall",
    "mallocCountTotal",
    "memoryLeaked",
    "syscalls",
    "readSyscalls",
    "readBytesLogical",
    "readBytesPhysical",
    "writeSyscalls",
    "writeBytesLogical",
    "writeBytesPhysical",
    "instructions",
    "objectAllocCount",
    "retainCount",
    "releaseCount",
    "retainReleaseDelta",
}

NON_COUNTABLE = {"cpuSystem", "cpuTotal", "cpuUser", "wallClock"}


def load_baseline(path):
    with open(path, "r", encoding="utf-8") as handle:
        data = json.load(handle)
    raw = data.get("results", [])
    if len(raw) % 2 != 0:
        raise ValueError(f"Unexpected results layout in {path}")
    results = {}
    for index in range(0, len(raw), 2):
        ident = raw[index]
        metrics = raw[index + 1]
        key = (ident.get("target", ""), ident.get("name", ""))
        results[key] = metrics
    return results


def metric_key(metric_obj):
    if not isinstance(metric_obj, dict) or not metric_obj:
        return "unknown", None
    key = next(iter(metric_obj.keys()))
    if key == "custom":
        custom = metric_obj.get("custom") or {}
        name = custom.get("name", "custom")
        return f"custom:{name}", custom
    return key, None


def leading_zero_bit_count_64(value):
    return 64 - value.bit_length() if value else 64


def bucket_index_for_value(value, sub_bucket_mask, leading_zero_count_base):
    return leading_zero_count_base - leading_zero_bit_count_64(value | sub_bucket_mask)


def sub_bucket_index_for_value(value, bucket_index, unit_magnitude):
    return int(value >> (bucket_index + unit_magnitude))


def value_from(bucket_index, sub_bucket_index, unit_magnitude):
    return int(sub_bucket_index) << (bucket_index + unit_magnitude)


def value_from_index(
    index, sub_bucket_half_count_magnitude, sub_bucket_half_count, unit_magnitude
):
    bucket_index = (index >> sub_bucket_half_count_magnitude) - 1
    sub_bucket_index = (index & (sub_bucket_half_count - 1)) + sub_bucket_half_count
    if bucket_index < 0:
        sub_bucket_index -= sub_bucket_half_count
        bucket_index = 0
    return value_from(bucket_index, sub_bucket_index, unit_magnitude)


def size_of_equivalent_range(
    bucket_index, sub_bucket_index, sub_bucket_count, unit_magnitude
):
    adjusted_bucket = bucket_index + 1 if sub_bucket_index >= sub_bucket_count else bucket_index
    return 1 << (unit_magnitude + adjusted_bucket)


def lowest_equivalent_for_value(
    value, sub_bucket_mask, leading_zero_count_base, unit_magnitude, sub_bucket_count
):
    bucket_index = bucket_index_for_value(value, sub_bucket_mask, leading_zero_count_base)
    sub_bucket_index = sub_bucket_index_for_value(value, bucket_index, unit_magnitude)
    return value_from(bucket_index, sub_bucket_index, unit_magnitude)


def highest_equivalent_for_value(
    value, sub_bucket_mask, leading_zero_count_base, unit_magnitude, sub_bucket_count
):
    bucket_index = bucket_index_for_value(value, sub_bucket_mask, leading_zero_count_base)
    sub_bucket_index = sub_bucket_index_for_value(value, bucket_index, unit_magnitude)
    size = size_of_equivalent_range(
        bucket_index, sub_bucket_index, sub_bucket_count, unit_magnitude
    )
    return value_from(bucket_index, sub_bucket_index, unit_magnitude) + size - 1


def histogram_min(histogram):
    counts = histogram.get("counts", [])
    total_count = histogram.get("_totalCount", 0)
    if not counts or total_count == 0 or counts[0] > 0:
        return 0
    return histogram.get("minNonZeroValue", 0)


def value_at_percentile(histogram, percentile):
    total_count = histogram.get("_totalCount", 0)
    if total_count == 0:
        return 0
    if percentile == 0.0:
        return histogram_min(histogram)
    if percentile >= 100.0:
        return histogram.get("maxValue", 0)

    requested = min(max(percentile, 0.0), 100.0)
    count_at_percentile = max(1, int(math.ceil(requested * total_count / 100.0)))

    counts = histogram.get("counts", [])
    sub_bucket_half_count_magnitude = histogram.get("subBucketHalfCountMagnitude", 0)
    sub_bucket_half_count = 1 << sub_bucket_half_count_magnitude
    sub_bucket_count = sub_bucket_half_count * 2
    unit_magnitude = histogram.get("unitMagnitude", 0)
    sub_bucket_mask = histogram.get("subBucketMask", 0)
    leading_zero_count_base = histogram.get("leadingZeroCountBase", 0)
    max_recorded = histogram.get("maxValue", 0)
    min_value = histogram_min(histogram)

    total_to_current = 0
    for index, count in enumerate(counts):
        total_to_current += int(count)
        if total_to_current >= count_at_percentile:
            value_at_index = value_from_index(
                index, sub_bucket_half_count_magnitude, sub_bucket_half_count, unit_magnitude
            )
            value = highest_equivalent_for_value(
                value_at_index,
                sub_bucket_mask,
                leading_zero_count_base,
                unit_magnitude,
                sub_bucket_count,
            )
            if value > max_recorded:
                value = max_recorded
            if value < min_value:
                value = min_value
            return value
    return 0


def scaled_time_units(time_units, scaling_factor):
    if time_units == "nanoseconds":
        return "nanoseconds"
    if time_units == "microseconds":
        return "microseconds" if scaling_factor == 1 else "nanoseconds"
    if time_units == "milliseconds":
        if scaling_factor == 1:
            return "milliseconds"
        if scaling_factor == 1_000:
            return "microseconds"
        return "nanoseconds"
    if time_units == "seconds":
        if scaling_factor == 1:
            return "seconds"
        if scaling_factor == 1_000:
            return "milliseconds"
        if scaling_factor == 1_000_000:
            return "microseconds"
        if scaling_factor == 1_000_000_000:
            return "nanoseconds"
    return "nanoseconds"


def remaining_scaling_factor(time_units, scaling_factor, stats_time_units):
    if stats_time_units != 0:
        return scaling_factor
    scaled = scaled_time_units(time_units, scaling_factor)
    if scaled == time_units:
        return scaling_factor
    time_units_magnitude = int(math.log10(TIME_UNITS_FACTOR[time_units]))
    scaled_magnitude = int(math.log10(TIME_UNITS_FACTOR[scaled]))
    scaling_magnitude = int(math.log10(scaling_factor))
    magnitude_delta = scaling_magnitude - (scaled_magnitude - time_units_magnitude)
    return int(10**magnitude_delta)


def normalize(value, time_units):
    divisor = TIME_UNITS_DIVISOR.get(time_units, 1)
    return int(round((value * 1000.0 / divisor) / 1000.0))


def scale(value, time_units, scaling_factor, stats_time_units):
    normalized = normalize(value, time_units)
    remaining = remaining_scaling_factor(time_units, scaling_factor, stats_time_units)
    return int(round((normalized * 1000.0 / remaining) / 1000.0))


def count_unit(time_units):
    return COUNT_UNIT_LABEL.get(time_units, "")


def scaled_scale_label(time_units, scaling_factor):
    scale_value = TIME_UNITS_DIVISOR.get(time_units, 1) * scaling_factor
    return SCALE_LABEL.get(scale_value, str(scale_value))


def unit_label(metric_name, time_units, scaling_factor, stats_time_units, use_scaling):
    if metric_name == "throughput":
        return scaled_scale_label(time_units, scaling_factor)
    if metric_name in NON_COUNTABLE:
        return TIME_UNIT_LABEL.get(time_units, time_units)
    unit_time = time_units
    if use_scaling and scaling_factor != 0 and stats_time_units == 0:
        unit_time = scaled_time_units(time_units, scaling_factor)
    return count_unit(unit_time)


def metric_p50_raw(item):
    hist = item.get("statistics", {}).get("histogram", {})
    return value_at_percentile(hist, 50.0)


def metric_scaled_value(p50_raw, time_units, scaling_factor, stats_time_units, use_scaling):
    adjust = (
        scale
        if (use_scaling and scaling_factor != 0)
        else lambda v, *_: normalize(v, time_units)
    )
    return adjust(p50_raw, time_units, scaling_factor, stats_time_units)


def metric_info(item, custom, metric_name):
    time_units = item.get("timeUnits", "nanoseconds")
    scaling_factor = int(item.get("scalingFactor", 1))
    stats_time_units = int(item.get("statistics", {}).get("timeUnits", 0))
    use_scaling = metric_name in USE_SCALING_FACTOR
    if custom:
        use_scaling = bool(custom.get("useScalingFactor", True))
    p50_raw = metric_p50_raw(item)
    return (
        metric_scaled_value(
            p50_raw,
            time_units,
            scaling_factor,
            stats_time_units,
            use_scaling,
        ),
        p50_raw,
        time_units,
        scaling_factor,
        stats_time_units,
        use_scaling,
    )


def percent_change(delta, base):
    if base in (None, 0):
        return "n/a"
    return f"{(delta / base) * 100:.1f}"


baseline_results = load_baseline(baseline_path)
target_results = load_baseline(target_path)

rows = []
bench_keys = sorted(set(baseline_results) & set(target_results))

for bench_key in bench_keys:
    base_metrics = {}
    target_metrics = {}
    for item in baseline_results[bench_key]:
        metric_name, custom = metric_key(item.get("metric"))
        base_metrics[metric_name] = (item, custom)
    for item in target_results[bench_key]:
        metric_name, custom = metric_key(item.get("metric"))
        target_metrics[metric_name] = (item, custom)
    for metric_name in sorted(set(base_metrics) & set(target_metrics)):
        base_item, base_custom = base_metrics[metric_name]
        target_item, target_custom = target_metrics[metric_name]
        base_p50, _, base_time_units, base_scale, base_stats_units, base_use_scaling = metric_info(
            base_item, base_custom, metric_name
        )
        target_p50, _, _, _, _, _ = metric_info(target_item, target_custom, metric_name)
        unit = unit_label(
            metric_name,
            base_time_units,
            base_scale,
            base_stats_units,
            base_use_scaling,
        )
        bench_label = bench_key[1]
        delta = target_p50 - base_p50
        delta_pct = percent_change(delta, base_p50)
        rows.append(
            [
                bench_label,
                metric_name,
                unit,
                str(base_p50),
                str(target_p50),
                str(delta),
                delta_pct,
            ]
        )

print("benchmark_name\tmetric_name\tunit\tbefore_metric\tafter_metric\tdelta\tdelta_%")
for row in rows:
    print("\t".join(row))
PY
