# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::PackagesController, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :public) }

  shared_examples 'having the feature flag "packagesProtectedPackages"' do
    it 'pushes the feature flag to the view' do
      is_expected.to have_gitlab_http_status(:ok)
      is_expected.to have_attributes(body: have_pushed_frontend_feature_flags(packagesProtectedPackages: true))
    end

    context 'when feature flag "packages_protected_packages" is disabled' do
      before do
        stub_feature_flags(packages_protected_packages: false)
      end

      it 'does not pushes the feature flag to the view' do
        is_expected.to have_gitlab_http_status(:ok)
        is_expected.to have_attributes(body: have_pushed_frontend_feature_flags(packagesProtectedPackages: false))
      end
    end
  end

  describe 'GET #index' do
    subject do
      get namespace_project_packages_path(namespace_id: project.namespace, project_id: project)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }

    it_behaves_like 'having the feature flag "packagesProtectedPackages"'
  end

  describe 'GET #show' do
    let_it_be(:package) { create(:package, project: project) }

    subject do
      get namespace_project_package_path(namespace_id: project.namespace, project_id: project, id: package.id)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }

    it_behaves_like 'having the feature flag "packagesProtectedPackages"'
  end
end
