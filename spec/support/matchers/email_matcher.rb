# frozen_string_literal: true

RSpec::Matchers.define :have_text_part_content do |expected|
  match do |actual|
    @actual = actual.text_part.body.to_s
    expect(@actual).to include(expected)
  end

  diffable
end

RSpec::Matchers.define :have_html_part_content do |expected|
  match do |actual|
    @actual = actual.html_part.body.to_s
    expect(@actual).to include(expected)
  end

  diffable
end
