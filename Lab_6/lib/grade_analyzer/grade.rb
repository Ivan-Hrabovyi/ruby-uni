require_relative 'errors'

module GradeAnalyzer
  # Одна оцінка: студент, предмет і бал від 0 до 100
  class Grade
    HEADERS = %w[name subject grade].freeze
    NAME_MAX = 50
    SUBJECT_MAX = 50
    # Ціле або дробове число з не більш ніж двома знаками після коми
    GRADE_PATTERN = /\A\d{1,3}(\.\d{1,2})?\z/

    attr_reader :name, :subject, :grade

    def initialize(name:, subject:, grade:)
      @name = name
      @subject = subject
      @grade = grade
    end

    # Створює оцінку з перевіркою. Кидає ValidationError зі списком усіх проблем.
    # grade може бути рядком з введення або з CSV (кома як роздільник також приймається).
    def self.build(name:, subject:, grade:)
      clean_name = clean_text(name)
      clean_subject = clean_text(subject)
      value = grade_value(grade)

      problems = []
      problems << "ім'я має бути непорожнім текстом до #{NAME_MAX} символів" unless valid_text?(clean_name, NAME_MAX)
      problems << "предмет має бути непорожнім текстом до #{SUBJECT_MAX} символів" unless valid_text?(clean_subject, SUBJECT_MAX)
      problems << 'оцінка має бути числом від 0 до 100 (наприклад, 85 або 85.5)' if value.nil?
      raise ValidationError.new(problems) unless problems.empty?

      new(name: clean_name, subject: clean_subject, grade: value)
    end

    # Та сама оцінка з іншим балом (для редагування); перевірка повторюється
    def with_grade(raw_value)
      self.class.build(name: name, subject: subject, grade: raw_value)
    end

    # 85.0 => "85", 85.5 => "85.5", 85.25 => "85.25"
    def self.format_value(value)
      return value.to_i.to_s if value == value.to_i

      ('%.2f' % value).sub(/0\z/, '')
    end

    def self.clean_text(raw)
      raw.to_s.strip.gsub(/\s+/, ' ')
    end

    def self.valid_text?(text, max_length)
      !text.empty? && text.length <= max_length && text.match?(/[[:alnum:]]/)
    end

    def self.grade_value(raw)
      text = raw.to_s.strip.tr(',', '.')
      return nil unless GRADE_PATTERN.match?(text)

      value = text.to_f
      value.between?(0, 100) ? value : nil
    end

    private_class_method :clean_text, :valid_text?, :grade_value
  end
end
