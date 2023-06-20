# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Admin::Dictionary, feature_category: :database do
  let(:admin) { create(:admin) }
  let(:path) { "/admin/databases/main/dictionary/tables/achievements" }

  describe 'GET admin/databases/:database_name/dictionary/tables/:table_name' do
    it_behaves_like "GET request permissions for admin mode"

    subject(:show_table_dictionary) do
      get api(path, admin, admin_mode: true)
    end

    context 'when the database does not exist' do
      it 'returns bad request' do
        get api("/admin/databases/#{non_existing_record_id}/dictionary/tables/achievements", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:bad_request)
      end
    end

    context 'when the table does not exist' do
      it 'returns not found' do
        get api("/admin/databases/main/dictionary/tables/#{non_existing_record_id}", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end

    context 'with a malicious table_name' do
      it 'returns an error' do
        get api("/admin/databases/main/dictionary/tables/%2E%2E%2Fpasswords.yml", admin, admin_mode: true)

        expect(response).to have_gitlab_http_status(:error)
      end
    end

    context 'when the params are correct' do
      let(:dictionary_dir) { Rails.root.join('spec/fixtures') }
      let(:path_file) { Rails.root.join(dictionary_dir, 'achievements.yml') }

      it 'fetches the table dictionary' do
        allow(Gitlab::Database::GitlabSchema).to receive(:dictionary_paths).and_return([dictionary_dir])

        expect(Gitlab::PathTraversal).to receive(:check_allowed_absolute_path_and_path_traversal!).twice.with(
          path_file.to_s, [dictionary_dir.to_s]).and_call_original

        show_table_dictionary

        aggregate_failures "testing response" do
          expect(json_response['table_name']).to eq('achievements')
          expect(json_response['feature_categories']).to eq(['feature_category_example'])
        end
      end
    end
  end
end
