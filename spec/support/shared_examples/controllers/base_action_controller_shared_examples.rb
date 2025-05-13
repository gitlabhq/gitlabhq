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
    end
  end
end
