# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating a Note' do
  include GraphqlHelpers

  let!(:note) { create(:note, note: original_body) }
  let(:original_body) { 'Initial body text' }
  let(:updated_body) { 'Updated body text' }
  let(:params) { { body: updated_body, confidential: true } }
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
      expect(note.confidential).to be_falsey
    end
  end

  context 'when the user has permission' do
    let(:current_user) { note.author }

    it_behaves_like 'a Note mutation when the given resource id is not for a Note'

    it 'updates the Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(note.reload.note).to eq(updated_body)
      expect(note.confidential).to be_truthy
    end

    it 'returns the updated Note' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq(updated_body)
      expect(mutation_response['note']['confidential']).to be_truthy
    end

    context 'when only confidential param is present' do
      let(:params) { { confidential: true } }

      it 'updates only the note confidentiality' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(note.reload.note).to eq(original_body)
        expect(note.confidential).to be_truthy
      end
    end

    context 'when only body param is present' do
      let(:params) { { body: updated_body } }

      before do
        note.update_column(:confidential, true)
      end

      it 'updates only the note body' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(note.reload.note).to eq(updated_body)
        expect(note.confidential).to be_truthy
      end
    end

    context 'when there are ActiveRecord validation errors' do
      let(:updated_body) { '' }

      it_behaves_like 'a mutation that returns errors in the response', errors: ["Note can't be blank"]

      it 'does not update the Note' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(note.reload.note).to eq(original_body)
        expect(note.confidential).to be_falsey
      end

      it 'returns the original Note' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['note']['body']).to eq(original_body)
        expect(mutation_response['note']['confidential']).to be_falsey
      end
    end

    context 'when body only contains quick actions' do
      let(:updated_body) { '/close' }

      it 'returns a nil note and empty errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to include(
          'errors' => [],
          'note' => nil
        )
      end
    end
  end
end
