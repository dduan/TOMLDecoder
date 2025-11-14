#include "DateRef.h"

#include <chrono>

#include <chrono>

int64_t hh_proleptic_seconds_since_unix_epoch(
    int32_t year,
    int32_t month,
    int32_t day,
    int32_t hour,
    int32_t minute,
    int32_t second
) {
    using namespace std::chrono;

    // C++20 chrono calendar types: proleptic Gregorian
    const std::chrono::year  y{year};
    const std::chrono::month m{static_cast<unsigned>(month)};
    const std::chrono::day   d{static_cast<unsigned>(day)};

    const std::chrono::year_month_day ymd{y / m / d};

    const std::chrono::sys_days days{ymd};

    const std::chrono::sys_seconds tp =
        days + hours{hour} + minutes{minute} + seconds{second};

    return tp.time_since_epoch().count(); // seconds since 1970-01-01T00:00:00Z
}
