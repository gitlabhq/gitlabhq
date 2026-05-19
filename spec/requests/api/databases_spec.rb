# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Databases, feature_category: :database do
  let_it_be(:user) { create(:user) }

  describe 'GET databases/:database_name/dictionary/tables' do
    let(:path) { "/databases/main/dictionary/tables" }

    it_behaves_like 'authorizing granular token permissions', :read_database_dictionary do
      let(:boundary_object) { :instance }
      let(:request) do
        get api(path, personal_access_token: pat)
      end
    end

    context 'when unauthenticated' do
      it 'returns unauthorized' do
        get api(path)

        expect(response).to have_gitlab_http_status(:unauthorized)
      end
    end

    context 'when the database does not exist' do
      it 'returns bad request' do
        get api("/databases/#{non_existing_record_id}/dictionary/tables", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'without table_size filter' do
      it 'returns dictionary tables for the given database' do
        get api(path, user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response).not_to be_empty
        expect(json_response.first).to include('table_name', 'feature_categories', 'table_size')
      end
    end

    context 'with table_size filter' do
      it 'returns only tables matching the given size' do
        get api("#{path}?table_size=over_limit", user)

        expect(response).to have_gitlab_http_status(:ok)
        expect(json_response).to be_an(Array)
        expect(json_response).not_to be_empty
        expect(json_response).to all(include('table_size' => 'over_limit'))
      end

      it 'returns bad request for invalid table_size' do
        get api("#{path}?table_size=invalid", user)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when filtering by database' do
      it 'returns only tables belonging to the ci database schemas' do
        get api("/databases/ci/dictionary/tables", user)

        table_names = json_response.pluck('table_name')
        expect(table_names).to include('p_ci_builds')
        expect(table_names).not_to include('achievements')
      end

      it 'returns only tables belonging to the main database schemas' do
        get api(path, user)

        table_names = json_response.pluck('table_name')
        expect(table_names).to include('achievements')
      end
    end
  end
end
