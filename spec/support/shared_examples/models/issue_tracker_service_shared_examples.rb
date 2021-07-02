# frozen_string_literal: true

RSpec.shared_examples 'issue tracker integration URL attribute' do |url_attr|
  it { is_expected.to allow_value('https://example.com').for(url_attr) }

  it { is_expected.not_to allow_value('example.com').for(url_attr) }
  it { is_expected.not_to allow_value('ftp://example.com').for(url_attr) }
  it { is_expected.not_to allow_value('herp-and-derp').for(url_attr) }
end

RSpec.shared_examples 'allows project key on reference pattern' do |url_attr|
  it 'allows underscores in the project name' do
    expect(described_class.reference_pattern.match('EXT_EXT-1234')[0]).to eq 'EXT_EXT-1234'
  end

  it 'allows numbers in the project name' do
    expect(described_class.reference_pattern.match('EXT3_EXT-1234')[0]).to eq 'EXT3_EXT-1234'
  end

  it 'requires the project name to begin with A-Z' do
    expect(described_class.reference_pattern.match('3EXT_EXT-1234')).to eq nil
    expect(described_class.reference_pattern.match('EXT_EXT-1234')[0]).to eq 'EXT_EXT-1234'
  end

  it 'does not allow issue number to finish with a letter' do
    expect(described_class.reference_pattern.match('EXT-123A')).to eq(nil)
  end
end
