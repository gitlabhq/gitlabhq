# frozen_string_literal: true

RSpec::Matchers.define :be_valid_json do
  match do |actual|
    Gitlab::Json.parse(actual).present?
  rescue JSON::ParserError => e
    @error = e
    false
  end

  def failure_message
    if @error
      "Parse failed with error: #{@error}"
    else
      "Parsing did not return any data"
    end
  end
end
