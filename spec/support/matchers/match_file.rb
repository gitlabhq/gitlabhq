# frozen_string_literal: true

RSpec::Matchers.define :match_file do |expected|
  match do |actual|
    expect(Digest::SHA256.hexdigest(actual)).to eq(Digest::SHA256.hexdigest(File.read(expected)))
  end

  failure_message do |actual|
    expected_sha = Digest::SHA256.hexdigest(File.read(expected))
    actual_sha = Digest::SHA256.hexdigest(actual)
    <<~MSG.chomp
      expected content to match file '#{expected}'
        expected SHA256: #{expected_sha} (#{File.size(expected)} bytes)
        actual SHA256:   #{actual_sha} (#{actual.bytesize} bytes)
    MSG
  end
end
