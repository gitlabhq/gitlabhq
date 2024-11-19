# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::CatalogController, feature_category: :pipeline_composition do
  let_it_be(:namespace) { create(:group) }
  let_it_be(:project) { create(:project, namespace: namespace) }
  let_it_be(:catalog_resource) { create(:ci_catalog_resource, :published, project: project) }

  let_it_be(:user) { create(:user) }

  before_all do
    catalog_resource.project.add_reporter(user)
  end

  shared_examples 'basic get requests' do |action|
    let(:path) do
      if action == :index
        explore_catalog_index_path
      else
        explore_catalog_path(catalog_resource)
      end
    end

    it 'responds with 200' do
      get path

      expect(response).to have_gitlab_http_status(:ok)
    end
  end

  describe 'GET #show' do
    before do
      sign_in(user)
    end

    it_behaves_like 'basic get requests', :show

    context 'when rendering an unpublished catalog resource' do
      it 'returns not found error' do
        unpublished_catalog_resource = create(:ci_catalog_resource, state: :unpublished)

        get explore_catalog_path(unpublished_catalog_resource)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'when rendering a published catalog resource' do
      it 'returns success response' do
        get explore_catalog_path(catalog_resource)

        expect(response).to have_gitlab_http_status(:success)
      end
    end
  end

  describe 'GET #index' do
    let_it_be(:event) { 'unique_users_visiting_ci_catalog' }

    subject(:visit_explore_catalog) { get explore_catalog_index_path }

    context 'with an authenticated user' do
      before do
        sign_in(user)
      end

      it_behaves_like 'basic get requests', :index

      it_behaves_like 'internal event tracking' do
        let(:namespace) { user.namespace }
        let(:project) { nil }
      end
    end

    context 'with an anonymous user' do
      it_behaves_like 'basic get requests', :index

      it_behaves_like 'internal event not tracked'
    end
  end
end
