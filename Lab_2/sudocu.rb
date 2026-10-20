class SudokuGame
  def initialize
    # Початкове поле 4x4 (0 означає порожню клітинку)
    # Це поле має єдиний правильний розв'язок
    @initial_board = [
      [1, 0, 3, 0],
      [0, 4, 0, 2],
      [2, 0, 4, 0],
      [0, 3, 0, 1]
    ]
    
    # Створюємо глибоку копію для ігрового поля, 
    # щоб не змінювати початкові значення
    @board = @initial_board.map(&:dup)
  end

  def play
    puts "============================="
    puts "  Вітаємо у грі Судоку 4x4!"
    puts "============================="
    
    loop do
      print_board
      
      if win?
        puts "\n🎉 ВІТАЄМО! Ви успішно розв'язали Судоку! 🎉"
        break
      end

      input = get_input
      break if input == :quit # Дострокове завершення
      
      next unless input # Якщо введення некоректне, повторюємо цикл

      row, col, num = input
      make_move(row, col, num)
    end
    
    puts "Дякуємо за гру!"
  end

  private

  # Виведення ігрового поля у консоль
  def print_board
    puts "\n    1 2   3 4"
    puts "  +-------+-------+"
    @board.each_with_index do |row, r_idx|
      print "#{r_idx + 1} | "
      row.each_with_index do |cell, c_idx|
        print(cell == 0 ? ". " : "#{cell} ")
        print "| " if c_idx == 1
      end
      puts
      puts "  +-------+-------+" if r_idx == 1 || r_idx == 3
    end
    puts
  end

  # Отримання та валідація введення від користувача
  def get_input
    print "Введіть рядок, стовпець та число (наприклад, '1 2 4')\n"
    print "(Введіть 'q' для виходу, або 0 замість числа, щоб очистити клітинку): "
    
    input = gets.chomp.strip.downcase

    return :quit if %w[q quit вихід].include?(input)

    parts = input.split
    if parts.size != 3
      puts "\n❌ Помилка: потрібно ввести рівно три числа, розділені пробілом."
      return nil
    end

    row, col, num = parts.map(&:to_i)

    unless (1..4).include?(row) && (1..4).include?(col)
      puts "\n❌ Помилка: рядок і стовпець мають бути в межах від 1 до 4."
      return nil
    end

    unless (0..4).include?(num)
      puts "\n❌ Помилка: число має бути від 1 до 4 (або 0 для очищення)."
      return nil
    end

    # Повертаємо індекси від 0 для зручної роботи з масивом
    [row - 1, col - 1, num]
  end

  # Логіка здійснення ходу
  def make_move(row, col, num)
    if locked_cell?(row, col)
      puts "\n❌ Помилка: Цю клітинку змінити неможливо (це початкове число)."
      return
    end

    if num == 0
      @board[row][col] = 0
      puts "\n✅ Клітинку очищено."
    elsif valid_move?(row, col, num)
      @board[row][col] = num
      puts "\n✅ Хід прийнято!"
    else
      puts "\n❌ Помилка: Хід порушує правила! Число #{num} вже є в цьому рядку, стовпці або блоці 2x2."
    end
  end

  # Перевірка чи не є клітинка початковою
  def locked_cell?(row, col)
    @initial_board[row][col] != 0
  end

  # Комплексна перевірка правил судоку
  def valid_move?(row, col, num)
    check_row(row, col, num) && 
    check_col(row, col, num) && 
    check_block(row, col, num)
  end

  # Перевірка рядка
  def check_row(row, col, num)
    @board[row].each_with_index do |cell, c_idx|
      return false if cell == num && c_idx != col
    end
    true
  end

  # Перевірка стовпця
  def check_col(row, col, num)
    @board.each_with_index do |r, r_idx|
      return false if r[col] == num && r_idx != row
    end
    true
  end

  # Перевірка блоку 2x2
  def check_block(row, col, num)
    # Визначаємо початкові координати блоку 2x2
    start_row = (row / 2) * 2
    start_col = (col / 2) * 2

    (start_row...start_row + 2).each do |r|
      (start_col...start_col + 2).each do |c|
        return false if @board[r][c] == num && (r != row || c != col)
      end
    end
    true
  end

  # Перевірка на перемогу (якщо немає нулів, то поле заповнене правильно)
  # Оскільки ми блокуємо неправильні ходи, відсутність нулів гарантує перемогу.
  def win?
    @board.none? { |row| row.include?(0) }
  end
end

# Запуск гри
game = SudokuGame.new
game.play