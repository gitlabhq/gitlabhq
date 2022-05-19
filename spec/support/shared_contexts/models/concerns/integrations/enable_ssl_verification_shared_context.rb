# frozen_string_literal: true

RSpec.shared_context Integrations::EnableSslVerification do
  # This is added to the global setup, to make sure all calls to
  # `Gitlab::HTTP` in the main model spec are passing the `verify:` option.
  before do
    allow(Gitlab::HTTP).to receive(:perform_request)
      .with(anything, anything, include(verify: true))
      .and_call_original
  end

  describe 'accessors' do
    it { is_expected.to respond_to(:enable_ssl_verification) }
    it { is_expected.to respond_to(:enable_ssl_verification?) }
  end

  describe '#initialize_properties' do
    it 'enables the setting by default' do
      expect(integration.enable_ssl_verification).to be(true)
    end

    it 'does not enable the setting if the record is already persisted' do
      allow(integration).to receive(:new_record?).and_return(false)

      integration.enable_ssl_verification = false
      integration.send(:initialize_properties)

      expect(integration.enable_ssl_verification).to be(false)
    end

    it 'does not enable the setting if a custom value was set' do
      integration = described_class.new(enable_ssl_verification: false)

      expect(integration.enable_ssl_verification).to be(false)
    end
  end

  describe '#fields' do
    it 'inserts the checkbox field after the first URL field, or at the end' do
      names = integration.fields.pluck(:name)
      url_index = names.index { |name| name.ends_with?('_url') }
      insert_index = url_index ? url_index + 1 : names.size - 1

      expect(names.index('enable_ssl_verification')).to eq insert_index
    end

    it 'does not insert the field repeatedly' do
      expect(integration.fields.pluck(:name)).to eq(integration.fields.pluck(:name))
    end
  end
end
