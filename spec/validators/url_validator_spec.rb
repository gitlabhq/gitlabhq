require 'spec_helper'

describe UrlValidator do
  let!(:badge) { build(:badge, link_url: 'http://www.example.com') }
  subject { validator.validate_each(badge, :link_url, badge.link_url) }

  include_examples 'url validator examples', described_class::DEFAULT_PROTOCOLS

  context 'by default' do
    let(:validator) { described_class.new(attributes: [:link_url]) }

    it 'does not block urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors.empty?).to be true
    end

    it 'does not block urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors.empty?).to be true
    end
  end

  context 'when allow_localhost is set to false' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_localhost: false) }

    it 'blocks urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors.empty?).to be false
    end
  end

  context 'when allow_local_network is set to false' do
    let(:validator) { described_class.new(attributes: [:link_url], allow_local_network: false) }

    it 'blocks urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors.empty?).to be false
    end
  end

  context 'when ports is set' do
    let(:validator) { described_class.new(attributes: [:link_url], ports: [443]) }

    it 'blocks urls with a different port' do
      subject

      expect(badge.errors.empty?).to be false
    end
  end
end
