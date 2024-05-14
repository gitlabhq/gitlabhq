# frozen_string_literal: true

# Requires `request` subject to be defined
#
# subject(:request) { get root_path }
RSpec.shared_examples 'Base action controller' do
  describe 'security headers' do
    describe 'Cross-Security-Policy' do
      context 'when configuring snowplow' do
        let(:snowplow_host) { 'snowplow.example.com' }

        shared_examples 'snowplow is not in the CSP' do
          it 'does not add the snowplow collector hostname to the CSP' do
            request

            expect(response.headers['Content-Security-Policy']).not_to include(snowplow_host)
          end
        end

        context 'when snowplow is enabled' do
          before do
            stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: snowplow_host)
          end

          it 'adds snowplow to the csp' do
            request

            expect(response.headers['Content-Security-Policy']).to include(snowplow_host)
          end
        end

        context 'when snowplow is enabled but host is not configured' do
          before do
            stub_application_setting(snowplow_enabled: true, snowplow_collector_hostname: nil)
          end

          it_behaves_like 'snowplow is not in the CSP'
        end

        context 'when snowplow is disabled' do
          before do
            stub_application_setting(snowplow_enabled: false, snowplow_collector_hostname: snowplow_host)
          end

          it_behaves_like 'snowplow is not in the CSP'
        end
      end

      context 'when configuring vite' do
        let(:vite_hmr_websocket_url) { "ws://gitlab.example.com:3808" }
        let(:vite_hmr_http_url) { "http://gitlab.example.com:3808" }
        let(:vite_gitlab_url) { Gitlab::Utils.append_path(Gitlab.config.gitlab.url, 'vite-dev/') }

        context 'when vite enabled during development',
          skip: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424334' do
          before do
            stub_rails_env('development')
            allow(ViteHelper).to receive(:vite_enabled?).and_return(true)
            allow(BaseActionController.helpers).to receive(:vite_enabled?).and_return(true)
            allow(BaseActionController.helpers).to receive(:vite_hmr_websocket_url).and_return(vite_hmr_websocket_url)
            allow(BaseActionController.helpers).to receive(:vite_hmr_http_url).and_return(vite_hmr_http_url)
          end

          it 'adds vite csp' do
            request

            expect(response.headers['Content-Security-Policy']).to include("#{vite_hmr_websocket_url}/vite-dev/")
            expect(response.headers['Content-Security-Policy']).to include("#{vite_hmr_http_url}/vite-dev/")
            expect(response.headers['Content-Security-Policy']).to include(vite_gitlab_url)
          end
        end

        context 'when vite disabled' do
          before do
            allow(BaseActionController.helpers).to receive(:vite_enabled?).and_return(false)
          end

          it "doesn't add vite csp" do
            request

            expect(response.headers['Content-Security-Policy']).not_to include(vite_hmr_websocket_url)
            expect(response.headers['Content-Security-Policy']).not_to include(vite_hmr_http_url)
            expect(response.headers['Content-Security-Policy']).not_to include(vite_gitlab_url)
          end
        end
      end
    end
  end
end
