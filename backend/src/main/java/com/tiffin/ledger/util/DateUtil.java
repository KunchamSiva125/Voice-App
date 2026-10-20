package com.tiffin.ledger.util;

import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;

public final class DateUtil {

    public static final ZoneId IST_ZONE = ZoneId.of("Asia/Kolkata");
    public static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    private DateUtil() {}

    /**
     * Gets today's business date in Asia/Kolkata timezone.
     */
    public static LocalDate getTodayIst() {
        return LocalDate.now(IST_ZONE);
    }

    /**
     * Converts an Instant to LocalDate in Asia/Kolkata.
     */
    public static LocalDate toLocalDateIst(Instant instant) {
        if (instant == null) return getTodayIst();
        return instant.atZone(IST_ZONE).toLocalDate();
    }

    /**
     * Start of day (00:00:00.000) for given local date in Asia/Kolkata as UTC Instant.
     */
    public static Instant getStartOfDayIst(LocalDate date) {
        return date.atStartOfDay(IST_ZONE).toInstant();
    }

    /**
     * End of day (23:59:59.999999999) for given local date in Asia/Kolkata as UTC Instant.
     */
    public static Instant getEndOfDayIst(LocalDate date) {
        return date.atTime(23, 59, 59, 999_999_999).atZone(IST_ZONE).toInstant();
    }

    /**
     * Parses ISO string or returns today's date in Asia/Kolkata.
     */
    public static LocalDate parseDateOrToday(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) {
            return getTodayIst();
        }
        try {
            return LocalDate.parse(dateStr.trim(), DATE_FORMATTER);
        } catch (Exception e) {
            return getTodayIst();
        }
    }
}
