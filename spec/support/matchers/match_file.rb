# frozen_string_literal: true

RSpec::Matchers.define :match_file do |expected|
  match do |actual|
    expect(Digest::MD5.hexdigest(actual)).to eq(Digest::MD5.hexdigest(File.read(expected)))
  end
end
