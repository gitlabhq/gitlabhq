# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Destroying a Note', feature_category: :team_planning do
  include GraphqlHelpers

  let(:noteable) { create(:work_item) }
  let!(:note) { create(:note, noteable: noteable, project: noteable.project) }
  let(:global_note_id) { GitlabSchema.id_from_object(note).to_s }
  let(:variables) { { id: global_note_id } }
  let(:mutation) { graphql_mutation(:destroy_note, variables) }

  def mutation_response
    graphql_mutation_response(:destroy_note)
  end

  context 'when the user does not have permission' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not destroy the Note' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { Note.count }
    end
  end

  context 'when the user has permission' do
    let(:current_user) { note.author }

    it_behaves_like 'a Note mutation when the given resource id is not for a Note'

    it 'destroys the Note' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.to change { Note.count }.by(-1)
    end

    it 'returns an empty Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response).to have_key('note')
      expect(mutation_response['note']).to be_nil
    end

    context 'when note is system' do
      let!(:note) { create(:note, :system) }

      it 'does not destroy system note' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.not_to change { Note.count }
      end
    end

    context 'without notes widget' do
      before do
        WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
      end

      it 'does not update the Note' do
        expect do
          post_graphql_mutation(mutation, current_user: current_user)
        end.to not_change { Note.count }
      end

      it_behaves_like 'a mutation that returns top-level errors',
        errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
    end
  end
end
