# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Packages::PackagesController, feature_category: :package_registry do
  let_it_be(:project) { create(:project, :public) }

  describe 'GET #index' do
    subject do
      get namespace_project_packages_path(namespace_id: project.namespace, project_id: project)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end

  describe 'GET #show' do
    let_it_be(:package) { create(:generic_package, project: project) }

    subject do
      get namespace_project_package_path(namespace_id: project.namespace, project_id: project, id: package.id)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end
end
