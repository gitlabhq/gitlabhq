# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Explore::CatalogController, feature_category: :pipeline_composition do
  let_it_be(:user) { create(:user) }

  before do
    sign_in(user)
  end

  shared_examples 'basic get requests' do |action|
    let(:path) do
      if action == :index
        explore_catalog_index_path
      else
        explore_catalog_path(id: 1)
      end
    end

    context 'with FF `global_ci_catalog`' do
      before do
        stub_feature_flags(global_ci_catalog: true)
      end

      it 'responds with 200' do
        get path

        expect(response).to have_gitlab_http_status(:ok)
      end
    end

    context 'without FF `global_ci_catalog`' do
      before do
        stub_feature_flags(global_ci_catalog: false)
      end

      it 'responds with 404' do
        get path

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end

  describe 'GET #show' do
    it_behaves_like 'basic get requests', :show
  end

  describe 'GET #index' do
    it_behaves_like 'basic get requests', :index
  end
end
