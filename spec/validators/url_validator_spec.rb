require 'spec_helper'

describe UrlValidator do
  let(:validator) { described_class.new(attributes: [:link_url],  **options) }
  let!(:badge) { build(:badge) }

  subject { validator.validate_each(badge, :link_url, badge.link_url) }

  describe '#validates_each' do
    context 'with no options' do
      let(:options) { {} }

      it 'allows http and https protocols by default' do
        expect(validator.send(:default_options)[:protocols]).to eq %w(http https)
      end

      it 'checks that the url structure is valid' do
        badge.link_url = 'http://www.google.es/%{whatever}'

        subject

        expect(badge.errors.empty?).to be false
      end
    end

    context 'with protocols' do
      let(:options) { { protocols: %w(http) } }

      it 'allows urls with the defined protocols' do
        badge.link_url = 'http://www.example.com'

        subject

        expect(badge.errors.empty?).to be true
      end

      it 'add error if the url protocol does not match the selected ones' do
        badge.link_url = 'https://www.example.com'

        subject

        expect(badge.errors.empty?).to be false
      end
    end
  end
end
