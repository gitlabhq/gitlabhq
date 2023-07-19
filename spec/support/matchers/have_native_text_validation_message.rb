# frozen_string_literal: true

RSpec::Matchers.define :have_native_text_validation_message do |field|
  match do |page|
    message = page.find_field(field).native.attribute('validationMessage')
    expect(message).to match(/Please fill [a-z]+ this field./)
  end
end
