require_relative 'errors'
require_relative 'statistics'
require_relative 'table'

module GradeAnalyzer
  # Текстовий статистичний звіт і його збереження у файл
  module Report
    module_function

    def build(grades, now: Time.now)
      students = Statistics.student_averages(grades)
      subjects = Statistics.subject_averages(grades)

      lines = []
      lines << 'СТАТИСТИЧНИЙ ЗВІТ ПРО УСПІШНІСТЬ СТУДЕНТІВ'
      lines << "Дата формування: #{now.strftime('%Y-%m-%d %H:%M')}"
      lines << "Оцінок: #{grades.size}, студентів: #{students.size}, предметів: #{subjects.size}"
      lines << "Загальний середній бал: #{format_average(Statistics.overall_average(grades))}"

      lines << ''
      lines += section('1. ВСІ ОЦІНКИ')
      lines += grades.empty? ? ['Оцінок немає.'] : Table.render(Table.numbered(grades))

      lines << ''
      lines += section('2. СЕРЕДНІЙ БАЛ КОЖНОГО СТУДЕНТА')
      lines += students.empty? ? ['Даних немає.'] : students.map { |s| student_line(s) }

      lines << ''
      lines += section('3. НАЙВИЩИЙ І НАЙНИЖЧИЙ СЕРЕДНІЙ БАЛ')
      if students.empty?
        lines << 'Даних немає.'
      else
        lines << extremes_line('Найвищий', Statistics.highest(students))
        lines << extremes_line('Найнижчий', Statistics.lowest(students))
      end

      lines << ''
      lines += section('4. СЕРЕДНІЙ БАЛ ЗА ПРЕДМЕТАМИ')
      lines += subjects.empty? ? ['Даних немає.'] : subjects.map { |s| subject_line(s) }

      lines
    end

    def save(path, lines)
      temp_path = "#{path}.tmp"
      File.write(temp_path, lines.join("\n") + "\n")
      File.rename(temp_path, path)
    rescue SystemCallError, IOError => e
      raise StorageError, "не вдалося записати звіт #{path} (#{e.message})"
    end

    def section(title)
      [title, '-' * title.length]
    end

    def format_average(value)
      value.nil? ? 'немає даних' : ('%.2f' % value)
    end

    def student_line(student)
      "#{student[:name]} — #{format_average(student[:average])} (оцінок: #{student[:count]})"
    end

    def subject_line(subject)
      "#{subject[:subject]} — #{format_average(subject[:average])} (оцінок: #{subject[:count]})"
    end

    def extremes_line(label, students)
      names = students.map { |s| s[:name] }.join(', ')
      "#{label}: #{names} — #{format_average(students.first[:average])}"
    end
  end
end
