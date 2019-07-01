# frozen_string_literal: true

require 'spec_helper'

describe 'Destroying a Note' do
  include GraphqlHelpers

  let!(:note) { create(:note) }
  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(note).to_s
    }

    graphql_mutation(:destroy_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:destroy_note)
  end

  context 'when the user does not have permission' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not exist or you don\'t have permission to perform this action']

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
  end
end
