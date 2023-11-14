# frozen_string_literal: true

RSpec.shared_examples 'url validator examples' do |schemes|
  describe '#validate' do
    let(:validator) { described_class.new(attributes: [:link_url], **options) }
    let(:badge) { build(:badge, link_url: 'http://www.example.com') }

    subject { validator.validate(badge) }

    context 'with no options' do
      let(:options) { {} }

      it "allows #{schemes.join(',')} schemes by default" do
        expect(validator.options[:schemes]).to eq schemes
      end

      it 'checks that the url structure is valid' do
        badge.link_url = "#{badge.link_url}:invalid_port"

        subject

        expect(badge.errors).to be_present
      end
    end

    context 'with schemes' do
      let(:options) { { schemes: %w[http] } }

      it 'allows urls with the defined schemes' do
        subject

        expect(badge.errors).to be_empty
      end

      it 'add error if the url scheme does not match the selected ones' do
        badge.link_url = 'https://www.example.com'

        subject

        expect(badge.errors).to be_present
      end
    end
  end
end

RSpec.shared_examples 'public url validator examples' do |setting|
  let(:validator) { described_class.new(attributes: [:link_url]) }
  let(:badge) { build(:badge, link_url: 'http://www.example.com') }

  subject { validator.validate(badge) }

  context 'by default' do
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

  context 'when local requests are allowed' do
    let!(:settings) { create(:application_setting) }

    before do
      stub_application_setting(setting)
    end

    it 'does not block urls pointing to localhost' do
      badge.link_url = 'https://127.0.0.1'

      subject

      expect(badge.errors).not_to be_present
    end

    it 'does not block urls pointing to the local network' do
      badge.link_url = 'https://192.168.1.1'

      subject

      expect(badge.errors).not_to be_present
    end
  end
end
