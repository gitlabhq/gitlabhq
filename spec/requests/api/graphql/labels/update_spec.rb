# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a label', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:label) { create(:label, project: project) }

  let(:input) do
    {
      id: label.to_global_id.to_s,
      archived: true
    }
  end

  let(:mutation) { graphql_mutation(:labelUpdate, input) }
  let(:mutation_response) { graphql_mutation_response(:label_update) }

  context 'when user does not have permissions' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions' do
    before_all do
      project.add_maintainer(current_user)
    end

    it 'updates the label archived status' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .to change { label.reload.archived }.from(false).to(true)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_data_at(:label_update, :label, :archived)).to be_truthy
    end

    it 'returns the updated label' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['label']).to include('archived' => true)
      expect(mutation_response['errors']).to be_empty
    end

    context 'when label does not exist' do
      let(:input) do
        {
          id: "gid://gitlab/Label/#{non_existing_record_id}",
          archived: true
        }
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(labels_archive: false)
      end

      it 'does not change the label archived status and returns an error' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { label.reload.archived }
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ["'labels_archive' feature flag is disabled"]
    end
  end
end
