# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Settings::PackagesAndRegistriesController, feature_category: :package_registry do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :private) }

  let(:packages_enabled) { true }
  let(:dependency_proxy_enabled) { true }

  before do
    stub_config(packages: { enabled: packages_enabled })
    stub_config(dependency_proxy: { enabled: dependency_proxy_enabled })
    sign_in(user)
  end

  describe 'GET #show' do
    subject(:request) { get group_settings_packages_and_registries_path(group) }

    context 'when user is not authorized' do
      it_behaves_like 'returning response status', :not_found
    end

    context 'when user is authorized' do
      before_all do
        group.add_owner(user)
      end

      it_behaves_like 'returning response status', :ok

      it_behaves_like 'pushed feature flag', :maven_central_request_forwarding

      it 'pushes adminDependencyProxy: true ability to frontend' do
        request

        expect(response.body).to have_pushed_frontend_ability(adminDependencyProxy: dependency_proxy_enabled)
      end

      context 'when packages config is disabled' do
        let(:packages_enabled) { false }

        it_behaves_like 'returning response status', :not_found
      end

      context 'when dependency proxy config is disabled' do
        let(:dependency_proxy_enabled) { false }

        it 'pushes adminDependencyProxy: false ability to frontend' do
          request

          expect(response.body).to have_pushed_frontend_ability(adminDependencyProxy: dependency_proxy_enabled)
        end
      end
    end
  end
end
