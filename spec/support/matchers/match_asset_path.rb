# frozen_string_literal: true

# add simpler way to match asset paths containing digest strings
RSpec::Matchers.define :match_asset_path do |expected|
  match do |actual|
    path = Regexp.escape(expected)
    extname = Regexp.escape(File.extname(expected))
    digest_regex = Regexp.new(path.sub(extname, "(?:-\\h+)?#{extname}") << '$')
    digest_regex =~ actual
  end

  failure_message do |actual|
    "expected that #{actual} would include an asset path for #{expected}"
  end

  failure_message_when_negated do |actual|
    "expected that #{actual} would not include an asset path for  #{expected}"
  end
end
