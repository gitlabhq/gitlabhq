# frozen_string_literal: true

# can be replaced with https://github.com/email-spec/email-spec/pull/196 in the future
RSpec::Matchers.define :have_plain_text_content do |expected_text|
  match do |actual_email|
    plain_text_body(actual_email).include? expected_text
  end

  failure_message do |actual_email|
    "Expected email\n#{plain_text_body(actual_email).indent(2)}\nto contain\n#{expected_text.indent(2)}"
  end

  def plain_text_body(email)
    email.text_part.body.to_s
  end
end
