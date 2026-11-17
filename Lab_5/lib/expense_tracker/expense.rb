require 'date'
require_relative 'errors'

module ExpenseTracker
  # Одна витрата. Створюється через build, який перевіряє всі поля.
  class Expense
    CATEGORIES = %w[food transport study entertainment other].freeze
    FIELDS = %w[id date amount_in_kopecks category description].freeze
    MAX_DESCRIPTION_LENGTH = 200
    DATE_PATTERN = /\A\d{4}-\d{2}-\d{2}\z/

    attr_reader :id, :date, :amount_in_kopecks, :category, :description

    def initialize(id:, date:, amount_in_kopecks:, category:, description:)
      @id = id
      @date = date
      @amount_in_kopecks = amount_in_kopecks
      @category = category
      @description = description
    end

    # Створює запис із хеша з рядковими ключами (файл, імпорт або форма).
    # Якщо якесь поле некоректне, кидає ValidationError зі списком усіх проблем.
    def self.build(attributes)
      raise ValidationError.new(['запис має бути JSON-об’єктом']) unless attributes.is_a?(Hash)

      missing = FIELDS - attributes.keys
      unknown = attributes.keys - FIELDS
      structure_problems = []
      structure_problems << "відсутні поля: #{missing.join(', ')}" unless missing.empty?
      structure_problems << "зайві поля: #{unknown.join(', ')}" unless unknown.empty?
      raise ValidationError.new(structure_problems) unless structure_problems.empty?

      problems = []
      problems << 'id має бути додатним цілим числом' unless positive_integer?(attributes['id'])

      date = parse_date(attributes['date'])
      problems << 'дата має бути реальною календарною датою у форматі YYYY-MM-DD' if date.nil?

      unless positive_integer?(attributes['amount_in_kopecks'])
        problems << 'сума має бути додатним цілим числом копійок'
      end

      unless CATEGORIES.include?(attributes['category'])
        problems << "категорія має бути однією з: #{CATEGORIES.join(', ')}"
      end

      raw_description = attributes['description']
      description = raw_description.is_a?(String) ? raw_description.strip : ''
      if description.empty? || description.length > MAX_DESCRIPTION_LENGTH
        problems << 'опис має бути непорожнім текстом до 200 символів'
      end

      raise ValidationError.new(problems) unless problems.empty?

      new(
        id: attributes['id'],
        date: date,
        amount_in_kopecks: attributes['amount_in_kopecks'],
        category: attributes['category'],
        description: description
      )
    end

    # Розбирає рядок YYYY-MM-DD; повертає Date або nil, якщо дата не існує
    def self.parse_date(text)
      return nil unless text.is_a?(String) && DATE_PATTERN.match?(text)

      year, month, day = text.split('-').map(&:to_i)
      Date.valid_date?(year, month, day) ? Date.new(year, month, day) : nil
    end

    def self.positive_integer?(value)
      value.is_a?(Integer) && value.positive?
    end

    def to_h
      {
        'id' => id,
        'date' => date.to_s,
        'amount_in_kopecks' => amount_in_kopecks,
        'category' => category,
        'description' => description
      }
    end
  end
end
