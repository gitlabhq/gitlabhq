# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::PackagesController, feature_category: :package_registry do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  describe 'GET #index' do
    subject do
      get group_packages_path(group_id: group.full_path)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end

  describe 'GET #show' do
    let_it_be(:package) { create(:generic_package, project: project) }

    subject do
      get group_package_path(group_id: group.full_path, id: package.id)
      response
    end

    it { is_expected.to have_gitlab_http_status(:ok) }
  end
end
