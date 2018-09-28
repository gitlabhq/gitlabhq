require 'spec_helper'

describe PublicUrlValidator do
  include_examples 'url validator examples', described_class::DEFAULT_PROTOCOLS

  context 'by default' do
    let(:validator) { described_class.new(attributes: [:link_url]) }
    let!(:badge) { build(:badge, link_url: 'http://www.example.com') }

    subject { validator.validate_each(badge, :link_url, badge.link_url) }

    it 'blocks urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors.empty?).to be false
    end

    it 'blocks urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors.empty?).to be false
    end
  end
end
