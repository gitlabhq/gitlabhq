# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::SsrfProtection, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:generic_package) { create(:generic_package, project: project) }
  let_it_be(:unsupported_package) { create(:conan_package, project: project) }

  describe '.params_for' do
    context 'when package is nil' do
      it 'returns empty hash' do
        expect(described_class.params_for(nil)).to eq({})
      end
    end

    context 'when package type is not supported' do
      it 'returns empty hash' do
        expect(described_class.params_for(unsupported_package)).to eq({})
      end
    end

    context 'when package type is supported' do
      it 'returns SSRF protection params for generic package' do
        result = described_class.params_for(generic_package)

        expect(result).to include(
          ssrf_filter: true,
          allow_localhost: true,
          allowed_endpoints: ObjectStoreSettings.enabled_endpoint_uris
        )
      end

      context 'when in production environment' do
        before do
          allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
        end

        context 'when local requests are allowed from webhooks' do
          before do
            stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
          end

          it 'allows localhost' do
            result = described_class.params_for(generic_package)
            expect(result[:allow_localhost]).to be true
          end
        end

        context 'when local requests are not allowed from webhooks' do
          before do
            stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
          end

          it 'does not allow localhost' do
            result = described_class.params_for(generic_package)
            expect(result[:allow_localhost]).to be false
          end
        end
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(generic_package_registry_ssrf_protection: false)
        end

        it 'returns empty hash for generic package' do
          expect(described_class.params_for(generic_package)).to eq({})
        end
      end
    end
  end

  describe '.allow_localhost?' do
    context 'when in development environment' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
      end

      it 'returns true' do
        expect(described_class.allow_localhost?).to be true
      end
    end

    context 'when in production environment' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(false)
      end

      context 'when local requests are allowed from webhooks' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'returns true' do
          expect(described_class.allow_localhost?).to be true
        end
      end

      context 'when local requests are not allowed from webhooks' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: false)
        end

        it 'returns false' do
          expect(described_class.allow_localhost?).to be false
        end
      end
    end
  end
end
