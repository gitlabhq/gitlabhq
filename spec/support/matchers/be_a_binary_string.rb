RSpec::Matchers.define :be_a_binary_string do |_|
  match do |actual|
    actual.is_a?(String) && actual.encoding == Encoding.find('ASCII-8BIT')
  end

  description do
    "be a String with binary encoding"
  end
end
