import Foundation

enum DateAgeUtility {
    /// Returns the number of days in a given month and year using the Gregorian calendar.
    static func daysInMonth(_ month: Int, year: Int) -> Int {
        var components = DateComponents()
        components.year = year
        components.month = month
        let calendar = Calendar(identifier: .gregorian)
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date) else {
            return 31
        }
        return range.count
    }

    /// Builds a Date from day, month, and year components if valid.
    static func makeDate(day: Int, month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.calendar = Calendar(identifier: .gregorian)
        components.year = year
        components.month = month
        components.day = day
        components.hour = 12
        guard let date = components.date else { return nil }
        let check = Calendar(identifier: .gregorian).dateComponents([.year, .month, .day], from: date)
        guard check.year == year, check.month == month, check.day == day else {
            return nil
        }
        return date
    }

    /// Calculates exact age in full years considering day, month, and year.
    /// Returns nil if the birth date is in the future.
    static func calculateAge(from birthDate: Date, relativeTo referenceDate: Date = Date()) -> Int? {
        let calendar = Calendar(identifier: .gregorian)
        let startOfBirth = calendar.startOfDay(for: birthDate)
        let startOfToday = calendar.startOfDay(for: referenceDate)

        if startOfBirth > startOfToday {
            return nil
        }

        let components = calendar.dateComponents([.year], from: startOfBirth, to: startOfToday)
        return components.year
    }

    static func isAdult(day: Int, month: Int, year: Int, minimumAge: Int = 18) -> (isValidDate: Bool, isFuture: Bool, age: Int?, isAdult: Bool) {
        guard let birthDate = makeDate(day: day, month: month, year: year) else {
            return (false, false, nil, false)
        }
        guard let age = calculateAge(from: birthDate) else {
            return (true, true, nil, false)
        }
        return (true, false, age, age >= minimumAge)
    }
}
