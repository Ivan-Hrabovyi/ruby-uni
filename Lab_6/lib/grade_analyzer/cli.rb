require_relative 'errors'
require_relative 'grade'
require_relative 'gradebook'
require_relative 'report'
require_relative 'statistics'
require_relative 'table'

module GradeAnalyzer
  # Інтерактивне меню. Будь-яка помилка показується, і користувач повертається до меню.
  class CLI
    MENU = <<~TEXT.freeze
      ===== Аналіз успішності студентів =====
      1. Показати всі оцінки
      2. Середній бал кожного студента
      3. Студенти з найвищим і найнижчим середнім балом
      4. Середній бал за предметами
      5. Пошук студента за іменем
      6. Додати оцінку
      7. Редагувати оцінку
      8. Видалити оцінку
      9. Сформувати звіт (report.txt)
      0. Вихід
    TEXT

    CONFIRMATIONS = %w[так т yes y].freeze

    def initialize(gradebook, report_path:, input: $stdin, output: $stdout)
      @gradebook = gradebook
      @report_path = report_path
      @input = input
      @output = output
    end

    def run
      loop do
        say "\n#{MENU}"
        command = ask('Оберіть дію: ')
        break if command == '0'

        begin
          dispatch(command)
        rescue Error => e
          show_error(e)
        rescue EndOfInput
          raise
        rescue StandardError => e
          say "Несподівана помилка: #{e.message}"
        end
      end
      say 'Роботу завершено. До побачення!'
    rescue EndOfInput
      say "\nВведення завершено. Роботу завершено."
    end

    private

    def dispatch(command)
      case command
      when '1' then show_all
      when '2' then show_student_averages
      when '3' then show_extremes
      when '4' then show_subject_averages
      when '5' then search_student
      when '6' then add_grade
      when '7' then edit_grade
      when '8' then delete_grade
      when '9' then generate_report
      else raise InputError, "Невідома команда «#{command}». Оберіть номер від 0 до 9."
      end
    end

    def show_all
      return say('Оцінок ще немає.') unless @gradebook.any?

      show_table(Table.numbered(@gradebook.grades))
    end

    def show_student_averages
      students = Statistics.student_averages(@gradebook.grades)
      return say('Оцінок ще немає.') if students.empty?

      students.each { |s| say("#{s[:name]}: #{format(s[:average])} (оцінок: #{s[:count]})") }
    end

    def show_extremes
      students = Statistics.student_averages(@gradebook.grades)
      return say('Оцінок ще немає.') if students.empty?

      say "Найвищий середній бал: #{names(Statistics.highest(students))} — #{format(Statistics.highest(students).first[:average])}"
      say "Найнижчий середній бал: #{names(Statistics.lowest(students))} — #{format(Statistics.lowest(students).first[:average])}"
    end

    def show_subject_averages
      subjects = Statistics.subject_averages(@gradebook.grades)
      return say('Оцінок ще немає.') if subjects.empty?

      subjects.each { |s| say("#{s[:subject]}: #{format(s[:average])} (оцінок: #{s[:count]})") }
    end

    def search_student
      query = ask('Ім\'я студента (або його частина): ')
      raise InputError, 'Ім\'я для пошуку не може бути порожнім.' if query.empty?

      numbered = Table.numbered(@gradebook.grades).select { |_n, g| Statistics.find_student([g], query).any? }
      if numbered.empty?
        return say("Студента «#{query}» не знайдено.")
      end

      show_table(numbered)
      matches = numbered.map(&:last)
      Statistics.student_averages(matches).each do |s|
        say "#{s[:name]}: середній бал #{format(s[:average])} (оцінок: #{s[:count]})"
      end
    end

    def add_grade
      record = @gradebook.add(
        name: ask('Ім\'я студента: '),
        subject: ask('Предмет: '),
        grade: ask('Оцінка (0–100): ')
      )
      say "Додано: #{record.name}, #{record.subject}, #{Grade.format_value(record.grade)}."
    end

    def edit_grade
      return say('Оцінок ще немає.') unless @gradebook.any?

      show_table(Table.numbered(@gradebook.grades))
      number = parse_number(ask('№ запису для редагування: '))
      current = @gradebook.fetch(number)
      say "Зараз: #{current.name}, #{current.subject}, #{Grade.format_value(current.grade)}"

      updated = @gradebook.update(number, ask('Нова оцінка (0–100): '))
      say "Оцінку змінено: #{updated.name}, #{updated.subject}, #{Grade.format_value(updated.grade)}."
    end

    def delete_grade
      return say('Оцінок ще немає.') unless @gradebook.any?

      show_table(Table.numbered(@gradebook.grades))
      number = parse_number(ask('№ запису для видалення: '))
      target = @gradebook.fetch(number)
      say "Видалити: #{target.name}, #{target.subject}, #{Grade.format_value(target.grade)}?"

      if CONFIRMATIONS.include?(ask('Підтвердіть (так/ні): ').downcase)
        @gradebook.delete(number)
        say 'Запис видалено.'
      else
        say 'Видалення скасовано.'
      end
    end

    def generate_report
      lines = Report.build(@gradebook.grades)
      Report.save(@report_path, lines)
      say "Звіт збережено у файлі #{@report_path}."
    end

    def parse_number(text)
      raise InputError, '№ запису має бути цілим додатним числом.' unless text.match?(/\A\d+\z/)

      text.to_i
    end

    def show_table(pairs)
      Table.render(pairs).each { |line| say(line) }
    end

    def names(students)
      students.map { |s| s[:name] }.join(', ')
    end

    def format(value)
      ('%.2f' % value)
    end

    def show_error(error)
      error.lines.each_with_index do |line, index|
        say index.zero? ? "Помилка: #{line}" : "  - #{line}"
      end
    end

    def ask(prompt)
      @output.print(prompt)
      @output.flush
      line = @input.gets
      raise EndOfInput if line.nil?

      text = line.dup.force_encoding(Encoding::UTF_8)
      raise InputError, 'Введення має бути у кодуванні UTF-8.' unless text.valid_encoding?

      text.strip
    end

    def say(text)
      @output.puts(text)
    end
  end
end
