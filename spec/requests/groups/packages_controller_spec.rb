# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::PackagesController, feature_category: :package_registry do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  describe 'GET #show' do
    let_it_be(:package) { create(:package, project: project) }

    subject do
      get group_package_path(group_id: group.full_path, id: package.id)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }

    it { is_expected.to have_attributes(body: have_pushed_frontend_feature_flags(packagesProtectedPackages: true)) }

    context 'when feature flag "packages_protected_packages" is disabled' do
      before do
        stub_feature_flags(packages_protected_packages: false)
      end

      it { is_expected.to have_gitlab_http_status(:ok) }

      it { is_expected.to have_attributes(body: have_pushed_frontend_feature_flags(packagesProtectedPackages: false)) }
    end
  end
end
