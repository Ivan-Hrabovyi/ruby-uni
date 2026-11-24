require 'csv'
require_relative 'errors'
require_relative 'grade'

module GradeAnalyzer
  # Результат завантаження: список оцінок і необов'язкове повідомлення для користувача
  LoadResult = Struct.new(:grades, :notice)

  # Читання і запис CSV-файлу з оцінками
  class CsvStorage
    attr_reader :path

    def initialize(path)
      @path = path
    end

    # Відсутній або порожній файл — порожній список з повідомленням.
    # Некоректні дані — ValidationError; файл при цьому не змінюється.
    def load
      unless File.exist?(path)
        return LoadResult.new([], "Файл #{path} не знайдено. Він буде створений після першої зміни.")
      end

      text = read_text
      if text.strip.empty?
        return LoadResult.new([], "Файл #{path} порожній. Дані з'являться після першого додавання.")
      end

      LoadResult.new(parse(text), nil)
    end

    # Записує через тимчасовий файл, щоб збій не зіпсував наявні дані
    def save(grades)
      temp_path = "#{path}.tmp"
      File.write(temp_path, self.class.generate(grades))
      File.rename(temp_path, path)
    rescue SystemCallError, IOError => e
      raise StorageError, "не вдалося записати #{path} (#{e.message})"
    end

    def self.generate(grades)
      CSV.generate do |csv|
        csv << Grade::HEADERS
        grades.each { |g| csv << [g.name, g.subject, Grade.format_value(g.grade)] }
      end
    end

    private

    # BOM від Блокнота прибирається автоматично
    def read_text
      File.read(path, encoding: 'bom|utf-8')
    rescue SystemCallError, IOError => e
      raise StorageError, "не вдалося прочитати #{path} (#{e.message})"
    end

    def parse(text)
      table = parse_table(text)
      check_headers(table.headers)

      grades = []
      problems = []
      table.each_with_index do |row, index|
        grades << Grade.build(name: row['name'], subject: row['subject'], grade: row['grade'])
      rescue ValidationError => e
        # Номер рядка з урахуванням заголовка у першому рядку файлу
        e.lines.each { |line| problems << "рядок #{index + 2}: #{line}" }
      end

      raise ValidationError.new(problems) unless problems.empty?

      grades
    end

    def parse_table(text)
      CSV.parse(
        text,
        headers: true,
        skip_blanks: true,
        header_converters: ->(header) { header.to_s.strip.downcase }
      )
    rescue CSV::MalformedCSVError => e
      raise ValidationError.new(["некоректний CSV: #{e.message}"])
    rescue ArgumentError, EncodingError
      raise ValidationError.new(['файл має бути в кодуванні UTF-8'])
    end

    def check_headers(headers)
      return if headers == Grade::HEADERS

      found = Array(headers).compact.join(',')
      raise ValidationError.new(["заголовок має бути «#{Grade::HEADERS.join(',')}», знайдено «#{found}»"])
    end
  end
end
