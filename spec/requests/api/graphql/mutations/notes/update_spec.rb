# frozen_string_literal: true

require 'spec_helper'

describe 'Updating a Note' do
  include GraphqlHelpers

  let!(:note) { create(:note, note: original_body) }
  let(:original_body) { 'Initial body text' }
  let(:updated_body) { 'Updated body text' }
  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(note).to_s,
      body: updated_body
    }

    graphql_mutation(:update_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:update_note)
  end

  context 'when the user does not have permission' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns top-level errors',
                    errors: ['The resource that you are attempting to access does not exist or you don\'t have permission to perform this action']

    it 'does not update the Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(note.reload.note).to eq(original_body)
    end
  end

  context 'when the user has permission' do
    let(:current_user) { note.author }

    it_behaves_like 'a Note mutation when the given resource id is not for a Note'

    it 'updates the Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(note.reload.note).to eq(updated_body)
    end

    it 'returns the updated Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq(updated_body)
    end

    context 'when there are ActiveRecord validation errors' do
      let(:updated_body) { '' }

      it_behaves_like 'a mutation that returns errors in the response', errors: ["Note can't be blank"]

      it 'does not update the Note' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(note.reload.note).to eq(original_body)
      end

      it 'returns the Note with its original body' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['note']['body']).to eq(original_body)
      end
    end
  end
end
