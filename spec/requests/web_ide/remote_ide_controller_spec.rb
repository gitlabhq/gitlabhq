# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WebIde::RemoteIdeController, feature_category: :remote_development do
  include ContentSecurityPolicyHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }

  let_it_be(:top_nav_partial) { 'layouts/header/_default' }

  let_it_be(:connection_token) { 'random1Connection3Token7' }
  let_it_be(:remote_path) { 'test/foo/README.md' }
  let_it_be(:return_url) { 'https://example.com/-/original/location' }
  let_it_be(:csp_nonce) { 'just=some=noncense' }

  let(:remote_host) { 'my-remote-host.example.com:1234' }
  let(:ff_vscode_web_ide) { true }

  before do
    sign_in(user)

    stub_feature_flags(vscode_web_ide: ff_vscode_web_ide)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:content_security_policy_nonce).and_return(csp_nonce)
    end
  end

  shared_examples_for '404 response' do
    it 'has not_found status' do
      post_to_remote_ide

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  describe "#index" do
    context "when feature flag is on *and* user is not using legacy Web IDE" do
      before do
        post_to_remote_ide
      end

      it "renders the correct layout" do
        expect(response).to render_template(layout: 'fullscreen')
      end

      it "renders with minimal: true" do
        # This indirectly tests that `minimal: true` was passed to the fullscreen layout
        expect(response).not_to render_template(top_nav_partial)
      end

      it "renders root element with data" do
        expected = {
          connection_token: connection_token,
          remote_host: remote_host,
          remote_path: remote_path,
          return_url: return_url,
          csp_nonce: csp_nonce
        }

        expect(find_root_element_data).to eq(expected)
      end

      it "updates the content security policy with the correct connect sources" do
        expect(find_csp_directive('connect-src')).to include(
          "ws://#{remote_host}",
          "wss://#{remote_host}",
          "http://#{remote_host}",
          "https://#{remote_host}"
        )
      end

      it "updates the content security policy with the correct frame sources" do
        expect(find_csp_directive('frame-src')).to include("http://www.example.com/assets/webpack/", "https://*.web-ide.gitlab-static.net/")
      end
    end

    context 'when remote_host does not have port' do
      let(:remote_host) { "my-remote-host.example.com" }

      before do
        post_to_remote_ide
      end

      it "updates the content security policy with the correct remote_host" do
        expect(find_csp_directive('connect-src')).to include(
          "ws://#{remote_host}",
          "wss://#{remote_host}",
          "http://#{remote_host}",
          "https://#{remote_host}"
        )
      end

      it 'renders remote_host in root element data' do
        expect(find_root_element_data).to include(remote_host: remote_host)
      end
    end

    context 'when feature flag is off' do
      let(:ff_vscode_web_ide) { false }

      it_behaves_like '404 response'
    end

    context "when the remote host is invalid" do
      let(:remote_host) { 'invalid:host:1:1:' }

      it_behaves_like '404 response'
    end
  end

  def find_root_element_data
    ide_attrs = Nokogiri::HTML.parse(response.body).at_css('#ide').attributes.transform_values(&:value)

    {
      connection_token: ide_attrs['data-connection-token'],
      remote_host: ide_attrs['data-remote-host'],
      remote_path: ide_attrs['data-remote-path'],
      return_url: ide_attrs['data-return-url'],
      csp_nonce: ide_attrs['data-csp-nonce']
    }
  end

  def post_to_remote_ide
    params = {
      connection_token: connection_token,
      return_url: return_url
    }

    post ide_remote_path(remote_host: remote_host, remote_path: remote_path), params: params
  end
end
