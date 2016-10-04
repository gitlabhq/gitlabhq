module CsvHelpers
  def csv
    CSV.parse(body, headers: true)
  end
end

RSpec.configure do |config|
  config.include CsvHelpers, type: :feature
end
