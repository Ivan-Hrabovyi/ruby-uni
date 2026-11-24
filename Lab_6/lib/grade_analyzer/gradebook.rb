require_relative 'errors'
require_relative 'grade'

module GradeAnalyzer
  # Набір оцінок у пам'яті. Кожна зміна спершу записується в CSV.
  # Якщо запис не вдався, список у пам'яті не змінюється.
  # Записи нумеруються з 1 у порядку файла (ці номери бачить користувач).
  class Gradebook
    attr_reader :grades

    def initialize(storage, grades = [])
      @storage = storage
      @grades = grades.dup
    end

    def any?
      !@grades.empty?
    end

    def add(name:, subject:, grade:)
      record = Grade.build(name: name, subject: subject, grade: grade)
      commit(@grades + [record])
      record
    end

    def fetch(number)
      @grades.fetch(index_for(number))
    end

    def update(number, raw_value)
      index = index_for(number)
      updated = @grades[index].with_grade(raw_value)
      new_grades = @grades.dup
      new_grades[index] = updated
      commit(new_grades)
      updated
    end

    def delete(number)
      index = index_for(number)
      removed = @grades[index]
      new_grades = @grades.dup
      new_grades.delete_at(index)
      commit(new_grades)
      removed
    end

    private

    def index_for(number)
      raise InputError, 'Записів ще немає.' unless any?

      unless number.is_a?(Integer) && number.between?(1, @grades.size)
        raise InputError, "Запису з номером #{number} немає. Допустимі номери: 1–#{@grades.size}."
      end

      number - 1
    end

    def commit(new_grades)
      @storage.save(new_grades)
      @grades = new_grades
    rescue StorageError => e
      raise StorageError, "#{e.message}. Зміну не збережено"
    end
  end
end
