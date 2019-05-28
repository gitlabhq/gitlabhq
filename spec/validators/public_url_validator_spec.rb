require 'spec_helper'

describe PublicUrlValidator do
  include_examples 'url validator examples', AddressableUrlValidator::DEFAULT_OPTIONS[:schemes]

  context 'by default' do
    let(:validator) { described_class.new(attributes: [:link_url]) }
    let!(:badge) { build(:badge, link_url: 'http://www.example.com') }

    subject { validator.validate(badge) }

    it 'blocks urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).to be_present
    end

    it 'blocks urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).to be_present
    end
  end
end
