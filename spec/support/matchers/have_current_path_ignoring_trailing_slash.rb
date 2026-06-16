# frozen_string_literal: true

RSpec::Matchers.define :have_current_path_ignoring_trailing_slash do |expected_path, **options|
  expected = expected_path.chomp('/')

  match do |_page|
    page.has_current_path?(expected, **options) || page.has_current_path?("#{expected}/", **options)
  end

  match_when_negated do |_page|
    page.has_no_current_path?(expected, **options) && page.has_no_current_path?("#{expected}/", **options)
  end

  failure_message do
    "expected current path to equal #{expected_path.inspect} (ignoring trailing slash), " \
      "but got #{page.current_path.inspect}"
  end
end
