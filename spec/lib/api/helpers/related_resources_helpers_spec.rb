# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::RelatedResourcesHelpers do
  subject(:helpers) do
    Class.new.include(described_class).new
  end

  describe '#expose_path' do
    let(:path) { '/api/v4/awesome_endpoint' }

    context 'empty relative URL root' do
      before do
        stub_config_setting(relative_url_root: '')
      end

      it 'returns the existing path' do
        expect(helpers.expose_path(path)).to eq(path)
      end
    end

    context 'slash relative URL root' do
      before do
        stub_config_setting(relative_url_root: '/')
      end

      it 'returns the existing path' do
        expect(helpers.expose_path(path)).to eq(path)
      end
    end

    context 'with relative URL root' do
      before do
        stub_config_setting(relative_url_root: '/gitlab/root')
      end

      it 'returns the existing path' do
        expect(helpers.expose_path(path)).to eq("/gitlab/root" + path)
      end
    end
  end

  describe '#expose_url' do
    let(:path) { '/api/v4/awesome_endpoint' }

    subject(:url) { helpers.expose_url(path) }

    def stub_default_url_options(protocol: 'http', host: 'example.com', port: nil, script_name: '')
      expect(Gitlab::Application.routes).to receive(:default_url_options)
        .and_return(protocol: protocol, host: host, port: port, script_name: script_name)
    end

    it 'respects the protocol if it is HTTP' do
      stub_default_url_options(protocol: 'http')

      is_expected.to start_with('http://')
    end

    it 'respects the protocol if it is HTTPS' do
      stub_default_url_options(protocol: 'https')

      is_expected.to start_with('https://')
    end

    it 'accepts the host if it contains an underscore' do
      stub_default_url_options(host: 'w_ww.example.com')

      is_expected.to start_with('http://w_ww.example.com/')
    end

    it 'accepts port to be nil' do
      stub_default_url_options(port: nil)

      is_expected.to start_with('http://example.com/')
    end

    it 'includes port if provided' do
      stub_default_url_options(port: 8080)

      is_expected.to start_with('http://example.com:8080/')
    end

    it 'includes the relative_url before the path if it is set' do
      stub_default_url_options(script_name: '/gitlab')

      is_expected.to start_with('http://example.com/gitlab/api/v4')
    end

    it 'includes the path after the host' do
      stub_default_url_options

      is_expected.to start_with('http://example.com/api/v4')
    end
  end
end
