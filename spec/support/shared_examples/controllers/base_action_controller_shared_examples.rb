# frozen_string_literal: true

# Requires `request` subject to be defined
#
# subject(:request) { get root_path }
RSpec.shared_examples 'Base action controller' do
  describe 'security headers' do
    describe 'Cross-Origin-Opener-Policy' do
      it 'sets the header' do
        request

        expect(response.headers['Cross-Origin-Opener-Policy']).to eq('same-origin')
      end

      context 'when coop_header feature flag is disabled' do
        it 'does not set the header' do
          stub_feature_flags(coop_header: false)

          request

          expect(response.headers['Cross-Origin-Opener-Policy']).to be_nil
        end
      end
    end
  end
end
