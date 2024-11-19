# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding a Note', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, developers: developer) }
  let_it_be_with_reload(:project) { create(:project, :repository, group: group) }
  let_it_be(:developer) { create(:user, developer_of: group) }
  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }
  let(:discussion) { nil }
  let(:head_sha) { nil }
  let(:body) { 'Body text' }
  let(:current_user) { user }
  let(:mutation) do
    variables = {
      noteable_id: GitlabSchema.id_from_object(noteable).to_s,
      discussion_id: (GitlabSchema.id_from_object(discussion).to_s if discussion),
      merge_request_diff_head_sha: head_sha.presence,
      body: body
    }

    graphql_mutation(:create_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_note)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    let(:current_user) { developer }

    it_behaves_like 'a working GraphQL mutation'

    it_behaves_like 'a Note mutation that creates a Note'

    it_behaves_like 'a Note mutation when there are active record validation errors'

    it_behaves_like 'a Note mutation when the given resource id is not for a Noteable'

    it_behaves_like 'a Note mutation when there are rate limit validation errors'

    it 'returns the note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq('Body text')
    end

    describe 'creating Notes in reply to a discussion' do
      context 'when the user does not have permission to create notes on the discussion' do
        let(:discussion) { create(:discussion_note).to_discussion }

        it_behaves_like 'a mutation that returns top-level errors',
          errors: ["The discussion does not exist or you don't have permission to perform this action"]
      end

      context 'when the user has permission to create notes on the discussion' do
        let(:discussion) { create(:discussion_note, project: project).to_discussion }

        it 'creates a Note in a discussion' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['note']['discussion']).to match a_graphql_entity_for(discussion)
        end

        context 'when the discussion_id is not for a Discussion' do
          let(:discussion) { create(:issue) }

          it_behaves_like 'a mutation that returns top-level errors' do
            let(:match_errors) { include(/ does not represent an instance of Discussion/) }
          end
        end
      end
    end

    context 'for an issue' do
      let_it_be_with_reload(:issue) { create(:issue, project: project) }
      let(:noteable) { issue }
      let(:mutation) { graphql_mutation(:create_note, variables) }
      let(:variables_extra) { {} }
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body
        }.merge(variables_extra)
      end

      context 'when using internal param' do
        let(:variables_extra) { { internal: true } }

        it_behaves_like 'a Note mutation with confidential notes'
      end

      context 'as work item' do
        let_it_be_with_reload(:work_item) { create(:work_item, :task, project: project) }
        let(:noteable) { work_item }

        context 'when using internal param' do
          let(:variables_extra) { { internal: true } }

          it_behaves_like 'a Note mutation with confidential notes'
        end

        context 'without notes widget' do
          before do
            WorkItems::Type.default_by_type(:task).widget_definitions.find_by_widget_type(:notes)
              .update!(disabled: true)
          end

          it_behaves_like 'a Note mutation that does not create a Note'
          it_behaves_like 'a mutation that returns top-level errors',
            errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
        end

        context 'when body contains quick actions' do
          it_behaves_like 'work item supports labels widget updates via quick actions'
          it_behaves_like 'work item does not support labels widget updates via quick actions'
          it_behaves_like 'work item supports assignee widget updates via quick actions'
          it_behaves_like 'work item does not support assignee widget updates via quick actions'
          it_behaves_like 'work item supports start and due date widget updates via quick actions'
          it_behaves_like 'work item does not support start and due date widget updates via quick actions'
          it_behaves_like 'work item supports type change via quick actions'
        end
      end
    end

    context 'when body only contains quick actions' do
      let(:head_sha) { noteable.diff_head_sha }
      let(:body) { '/merge' }

      it 'returns a nil note and info about the command in quickActionsStatus' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to include(
          'errors' => [],
          'note' => nil,
          'quickActionsStatus' => {
            "commandNames" => ["merge"],
            "commandsOnly" => true,
            "messages" => ["Merged this merge request."],
            "errorMessages" => nil
          })
      end

      it 'starts the merge process' do
        expect { post_graphql_mutation(mutation, current_user: current_user) }
          .to change { noteable.reload.merge_jid.present? }.from(false).to(true)
      end
    end
  end
end
