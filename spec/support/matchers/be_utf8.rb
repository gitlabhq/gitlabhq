# frozen_string_literal: true

RSpec::Matchers.define :be_utf8 do |_|
  match do |actual|
    actual.is_a?(String) && actual.encoding == Encoding.find('UTF-8')
  end

  description do
    "be a String with encoding UTF-8"
  end
end
