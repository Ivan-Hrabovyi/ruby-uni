require_relative 'grade'

module GradeAnalyzer
  # Таблиця оцінок для консолі та звіту. Працює з парами [номер, оцінка].
  module Table
    HEADERS = ['№', 'Студент', 'Предмет', 'Оцінка'].freeze

    module_function

    # Номери за порядком файла: 1, 2, 3...
    def numbered(grades)
      grades.each_with_index.map { |grade, index| [index + 1, grade] }
    end

    def render(pairs)
      rows = pairs.map do |number, grade|
        [number.to_s, grade.name, grade.subject, Grade.format_value(grade.grade)]
      end
      widths = HEADERS.each_index.map do |i|
        ([HEADERS[i]] + rows.map { |row| row[i] }).map(&:length).max
      end
      separator = widths.map { |w| '-' * w }.join('  ')

      [format_row(HEADERS, widths), separator, *rows.map { |row| format_row(row, widths) }]
    end

    def format_row(cells, widths)
      cells.each_with_index.map do |cell, i|
        right_aligned = [0, 3].include?(i)
        right_aligned ? cell.rjust(widths[i]) : cell.ljust(widths[i])
      end.join('  ').rstrip
    end
  end
end
