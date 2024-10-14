# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an abuse report note', feature_category: :insider_threat do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:note) { create(:abuse_report_note, note: 'note text') }

  let(:updated_body) { 'Updated body text' }
  let(:current_user) { user }
  let(:variables) do
    {
      id: GitlabSchema.id_from_object(note).to_s,
      body: updated_body
    }
  end

  let(:mutation) do
    graphql_mutation(:update_abuse_report_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:update_abuse_report_note)
  end

  context 'when the user does not have permission' do
    let(:current_user) { user }

    before do
      stub_feature_flags(abuse_report_notes: true)
    end

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the Note' do
      expect { post_graphql_mutation(mutation, current_user: current_user) }
        .not_to change { note.reload.note }
    end
  end

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

      context 'when params are valid' do
        it 'updates and returns the updated Note' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(note.reload.note).to eq(updated_body)
          expect(mutation_response['note']['body']).to eq(updated_body)
        end
      end

      context 'when body param is missing' do
        let(:variables) do
          {
            id: GitlabSchema.id_from_object(note).to_s
          }
        end

        it_behaves_like 'a mutation that returns top-level errors' do
          let(:match_errors) do
            contain_exactly(include("Expected value to not be null"))
          end
        end
      end

      context 'when body param is same as the current note body value' do
        let(:variables) do
          {
            id: GitlabSchema.id_from_object(note).to_s,
            body: 'note text'
          }
        end

        it 'returns the errors in the response' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(mutation_response['errors']).to include('The provided params did not update the note.')
        end
      end
    end
  end
end
