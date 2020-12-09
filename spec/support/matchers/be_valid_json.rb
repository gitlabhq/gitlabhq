# frozen_string_literal: true

RSpec::Matchers.define :be_valid_json do
  def according_to_schema(schema)
    @schema = schema
    self
  end

  match do |actual|
    data = Gitlab::Json.parse(actual)

    if @schema.present?
      @validation_errors = JSON::Validator.fully_validate(@schema, data)
      @validation_errors.empty?
    else
      data.present?
    end
  rescue JSON::ParserError => e
    @error = e
    false
  end

  def failure_message
    if @error
      "Parse failed with error: #{@error}"
    elsif @validation_errors.present?
      "Validation failed because #{@validation_errors.join(', and ')}"
    else
      "Parsing did not return any data"
    end
  end
end
