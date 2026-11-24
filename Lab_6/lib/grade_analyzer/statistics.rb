module GradeAnalyzer
  # Розрахунки без побічних ефектів. Середні округлюються до 2 знаків.
  module Statistics
    module_function

    def average(values)
      return nil if values.empty?

      (values.sum / values.size.to_f).round(2)
    end

    # Список hash-ів: { name:, average:, count: } за студентами (без урахування регістру)
    def student_averages(grades)
      grades.group_by { |g| normalize(g.name) }.map do |_key, items|
        { name: items.first.name, average: average(items.map(&:grade)), count: items.size }
      end.sort_by { |s| normalize(s[:name]) }
    end

    # Список hash-ів: { subject:, average:, count: } за предметами
    def subject_averages(grades)
      grades.group_by { |g| normalize(g.subject) }.map do |_key, items|
        { subject: items.first.subject, average: average(items.map(&:grade)), count: items.size }
      end.sort_by { |s| normalize(s[:subject]) }
    end

    def overall_average(grades)
      average(grades.map(&:grade))
    end

    # Усі студенти з найвищим середнім балом (може бути кілька)
    def highest(students)
      return [] if students.empty?

      top = students.map { |s| s[:average] }.max
      students.select { |s| s[:average] == top }
    end

    # Усі студенти з найнижчим середнім балом (може бути кілька)
    def lowest(students)
      return [] if students.empty?

      bottom = students.map { |s| s[:average] }.min
      students.select { |s| s[:average] == bottom }
    end

    # Оцінки студентів, чиє ім'я містить запит (без урахування регістру)
    def find_student(grades, query)
      needle = normalize(query)
      grades.select { |g| normalize(g.name).include?(needle) }
    end

    def normalize(text)
      text.to_s.strip.downcase
    end
  end
end
