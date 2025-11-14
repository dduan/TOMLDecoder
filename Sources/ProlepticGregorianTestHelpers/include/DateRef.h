#pragma once

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Proleptic Gregorian seconds since 1970-01-01T00:00:00Z
int64_t hh_proleptic_seconds_since_unix_epoch(
    int32_t year,
    int32_t month,
    int32_t day,
    int32_t hour,
    int32_t minute,
    int32_t second
);

#ifdef __cplusplus
}
#endif
