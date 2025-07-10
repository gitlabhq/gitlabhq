# frozen_string_literal: true

RSpec.shared_examples 'package registry SSRF protection' do
  context 'with custom object store endpoints' do
    let(:custom_endpoints) { ['https://custom-storage.example.com', 'https://backup.example.com'] }

    before do
      allow(ObjectStoreSettings).to receive(:enabled_endpoint_uris).and_return(custom_endpoints)
    end

    it 'includes custom endpoints in allowed_endpoints' do
      expect(Gitlab::Workhorse).to receive(:send_url).with(
        an_instance_of(String),
        hash_including(allowed_endpoints: custom_endpoints)
      ).and_call_original

      subject
    end
  end

  context 'when local requests are not allowed' do
    before do
      allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
    end

    it 'sets allow_localhost to false' do
      expect(Gitlab::Workhorse).to receive(:send_url).with(
        an_instance_of(String),
        hash_including(allow_localhost: false)
      ).and_call_original

      subject
    end
  end

  context 'when generic_package_registry_ssrf_protection is disabled' do
    before do
      stub_feature_flags(generic_package_registry_ssrf_protection: false)
    end

    it 'does not pass SSRF protection parameters' do
      expect(Gitlab::Workhorse).to receive(:send_url).and_wrap_original do |method, *args|
        expect(args.first).to be_an_instance_of(String)
        expect(args.last).not_to include(:ssrf_filter, :allow_localhost, :allowed_endpoints) if args.last.is_a?(Hash)

        method.call(*args)
      end

      subject
    end
  end
end
