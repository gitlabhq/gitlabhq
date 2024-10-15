# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding an abuse report note', feature_category: :insider_threat do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:abuse_report) { create(:abuse_report) }
  let_it_be(:discussion_note) { create(:abuse_report_discussion_note) }

  let(:discussion) { nil }
  let(:body) { 'Body text' }
  let(:current_user) { user }
  let(:mutation) do
    variables = {
      abuse_report_id: GitlabSchema.id_from_object(abuse_report).to_s,
      discussion_id: (GitlabSchema.id_from_object(discussion).to_s if discussion),
      body: body
    }

    graphql_mutation(:create_abuse_report_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_abuse_report_note)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    let(:current_user) { admin }

    context 'when abuse_report_notes FF is not enabled' do
      before do
        stub_feature_flags(abuse_report_notes: false)
      end

      it_behaves_like 'a mutation that returns a top-level access error'
    end

    context 'when abuse_report_notes FF is enabled' do
      before do
        stub_feature_flags(abuse_report_notes: true)
      end

      it_behaves_like 'a working GraphQL mutation'
      it_behaves_like 'a Note mutation when there are active record validation errors', model: AntiAbuse::Reports::Note

      it do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to change { AntiAbuse::Reports::Note.count }.by(1)
      end

      it 'returns the note' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['note']['body']).to eq('Body text')
      end

      describe 'creating Notes in reply to a discussion' do
        let(:discussion) { discussion_note.to_discussion }

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
  end
end
