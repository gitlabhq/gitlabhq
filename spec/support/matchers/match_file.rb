# frozen_string_literal: true

RSpec::Matchers.define :match_file do |expected|
  match do |actual|
    expect(Digest::SHA256.hexdigest(actual)).to eq(Digest::SHA256.hexdigest(File.read(expected)))
  end
end
