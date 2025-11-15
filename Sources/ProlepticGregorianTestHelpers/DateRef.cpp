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

    // WINDOWS FIX: Manually compute seconds to avoid chrono addition overflow
    // Get days as 64-bit count and manually add time components
    const int64_t days_count = days.time_since_epoch().count();
    const int64_t total_seconds = days_count * 86400LL + 
                                  static_cast<int64_t>(hour) * 3600LL +
                                  static_cast<int64_t>(minute) * 60LL +
                                  static_cast<int64_t>(second);
    
    return total_seconds;
}
