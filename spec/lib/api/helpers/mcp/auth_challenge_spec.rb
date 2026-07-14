# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::Mcp::AuthChallenge, feature_category: :mcp_server do
  let(:request) { instance_double(Grape::Request, path: request_path) }

  let(:instance) do
    Class.new do
      include API::Helpers::Mcp::AuthChallenge

      attr_reader :request

      def initialize(request)
        @request = request
      end
    end.new(request)
  end

  subject(:challenge) { instance.send(:mcp_www_authenticate_challenge) }

  context 'without a relative URL root' do
    let(:request_path) { '/api/v4/mcp' }

    before do
      stub_config_setting(url: 'https://gitlab.example.com', relative_url_root: '')
    end

    it 'advertises the protected resource metadata URL' do
      metadata_url = 'https://gitlab.example.com/.well-known/oauth-protected-resource/api/v4/mcp'

      expect(challenge).to eq(%(Bearer realm="GitLab", resource_metadata="#{metadata_url}"))
    end
  end

  context 'with a relative URL root (subpath install)' do
    let(:request_path) { '/gitlab/api/v4/mcp' }

    before do
      stub_config_setting(url: 'https://git.example.org/gitlab', relative_url_root: '/gitlab')
    end

    it 'strips the relative root so it is not duplicated in the metadata URL' do
      metadata_url = 'https://git.example.org/gitlab/.well-known/oauth-protected-resource/api/v4/mcp'

      expect(challenge).to eq(%(Bearer realm="GitLab", resource_metadata="#{metadata_url}"))
    end
  end
end
