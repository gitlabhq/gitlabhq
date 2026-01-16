# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update a label', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
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
    RSpec.shared_examples 'successfully updates the archived status' do
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
    end

    before_all do
      group.add_owner(current_user)
    end

    it_behaves_like 'successfully updates the archived status'

    context 'with group label' do
      let(:label) { create(:group_label, group: group) }

      it_behaves_like 'successfully updates the archived status'
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

    context 'when the label is not a project or group label' do
      let(:label) { create(:admin_label) }

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ['Label is not a project or group label.']
    end

    context 'with feature flag disabled' do
      let_it_be(:group) { create(:group) }

      before_all do
        group.add_maintainer(current_user)
      end

      before do
        stub_feature_flags(labels_archive: false)
      end

      it 'does not change the label archived status and returns an error' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .not_to change { label.reload.archived }
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: ["'labels_archive' feature flag is disabled"]

      context 'when the project belongs to a group' do
        before do
          project.group = group
          project.save!
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ["'labels_archive' feature flag is disabled"]
      end

      context 'when the label is a group label' do
        let(:label) { create(:group_label, group: group) }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ["'labels_archive' feature flag is disabled"]
      end
    end
  end
end
