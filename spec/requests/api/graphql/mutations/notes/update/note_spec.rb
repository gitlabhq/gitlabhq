# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a Note', feature_category: :team_planning do
  include GraphqlHelpers

  let!(:note) { create(:note, note: original_body) }
  let(:original_body) { 'Initial body text' }
  let(:updated_body) { 'Updated body text' }
  let(:params) { { body: updated_body } }
  let(:mutation) do
    variables = params.merge(id: GitlabSchema.id_from_object(note).to_s)

    graphql_mutation(:update_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:update_note)
  end

  context 'when the user does not have permission' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(note.reload.note).to eq(original_body)
    end
  end

  context 'when the user has permission' do
    let(:current_user) { note.author }

    it_behaves_like 'a Note mutation when the given resource id is not for a Note'

    it_behaves_like 'a Note mutation updates a note successfully'
    it_behaves_like 'a Note mutation update with errors'
    it_behaves_like 'a Note mutation update only with quick actions'

    context 'for work item' do
      let(:noteable) { create(:work_item) }
      let(:note) { create(:note, noteable: noteable, project: noteable.project, note: original_body) }

      it_behaves_like 'a Note mutation updates a note successfully'
      it_behaves_like 'a Note mutation update with errors'
      it_behaves_like 'a Note mutation update only with quick actions'

      context 'without notes widget' do
        before do
          WorkItems::Type.default_by_type(:issue).widget_definitions.find_by_widget_type(:notes).update!(disabled: true)
        end

        it 'does not update the Note' do
          post_graphql_mutation(mutation, current_user: current_user)

          expect(note.reload.note).to eq(original_body)
        end

        it_behaves_like 'a mutation that returns top-level errors',
          errors: [Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR]
      end
    end
  end
end
