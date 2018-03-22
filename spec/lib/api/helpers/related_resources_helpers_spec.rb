require 'spec_helper'

describe API::Helpers::RelatedResourcesHelpers do
  subject(:helpers) do
    Class.new.include(described_class).new
  end

  describe '#expose_url' do
    let(:path) { '/api/v4/awesome_endpoint' }
    subject(:url) { helpers.expose_url(path) }

    def stub_default_url_options(protocol: 'http', host: 'example.com', port: nil)
      expect(Gitlab::Application.routes).to receive(:default_url_options)
        .and_return(protocol: protocol, host: host, port: port)
    end

    it 'respects the protocol if it is HTTP' do
      stub_default_url_options(protocol: 'http')

      is_expected.to start_with('http://')
    end

    it 'respects the protocol if it is HTTPS' do
      stub_default_url_options(protocol: 'https')

      is_expected.to start_with('https://')
    end

    it 'accepts port to be nil' do
      stub_default_url_options(port: nil)

      is_expected.to start_with('http://example.com/')
    end

    it 'includes port if provided' do
      stub_default_url_options(port: 8080)

      is_expected.to start_with('http://example.com:8080/')
    end
  end
end
