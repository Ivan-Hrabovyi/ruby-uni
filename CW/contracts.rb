require "csv"
require "json"
require "fileutils"

INPUT_PATH = File.join(__dir__, "data", "contacts.csv")
OUTPUT_DIR = File.join(__dir__, "output")
# щось@щось.домен: без пробілів і без зайвих @
EMAIL_RE = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

unless File.exist?(INPUT_PATH)
  warn "Файл не знайдено: #{INPUT_PATH}"
  exit 1
end

valid  = []
errors = []

begin
  # with_index(2): номер рядка у файлі, заголовок має номер 1
  CSV.foreach(INPUT_PATH, headers: true, encoding: "UTF-8").with_index(2) do |row, line|
    name  = row["name"].to_s.strip
    email = row["email"].to_s.strip.downcase

    reasons = []
    reasons << "порожнє ім'я" if name.empty?
    reasons << "некоректний email" unless EMAIL_RE.match?(email)

    if reasons.empty?
      valid << { "name" => name, "email" => email }
    else
      errors << [line, reasons.join("; ")]
    end
  end
rescue CSV::MalformedCSVError => e
  warn "Помилка розбору CSV: #{e.message}"
  exit 1
end

FileUtils.mkdir_p(OUTPUT_DIR)

File.write(File.join(OUTPUT_DIR, "contacts.json"), JSON.pretty_generate(valid))

CSV.open(File.join(OUTPUT_DIR, "errors.csv"), "w") do |csv|
  csv << ["row", "reason"]
  errors.each { |line, reason| csv << [line, reason] }
end

puts "Коректних: #{valid.size}, з помилками: #{errors.size}"