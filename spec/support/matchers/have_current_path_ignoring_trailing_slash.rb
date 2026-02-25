# frozen_string_literal: true

RSpec::Matchers.define :have_current_path_ignoring_trailing_slash do |expected_path, **options|
  match do |_page|
    expected = expected_path.chomp('/')
    page.has_current_path?(expected, **options) || page.has_current_path?("#{expected}/", **options)
  end

  failure_message do
    "expected current path to equal #{expected_path.inspect} (ignoring trailing slash), " \
      "but got #{page.current_path.inspect}"
  end
end
