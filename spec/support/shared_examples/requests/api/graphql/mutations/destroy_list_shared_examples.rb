# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'board lists destroy request' do
  include GraphqlHelpers

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  shared_examples 'does not destroy the list and returns an error' do
    it 'does not destroy the list' do
      expect { subject }.not_to change { klass.count }
    end

    it 'returns an error and not nil list' do
      subject

      expect(mutation_response['errors']).not_to be_empty
      expect(mutation_response['list']).not_to be_nil
    end
  end

  context 'when the user does not have permission' do
    it 'does not destroy the list' do
      expect { subject }.not_to change { klass.count }
    end

    it 'returns an error' do
      subject

      expect(graphql_errors.first['message']).to include("The resource that you are attempting to access does not exist or you don't have permission to perform this action")
    end
  end

  context 'when the user has permission' do
    before do
      group.add_maintainer(current_user)
    end

    context 'when given id is not for a list' do
      # could be any non-list thing
      let_it_be(:list) { group }

      it 'returns an error' do
        subject

        expect(graphql_errors.first['message']).to include('does not represent an instance of')
      end
    end

    context 'when list does not exist' do
      let(:variables) do
        {
          list_id: "gid://gitlab/#{klass}/#{non_existing_record_id}"
        }
      end

      it 'returns a top level error' do
        subject

        expect(graphql_errors.first['message']).to include('No object found for')
      end
    end

    context 'when everything is ok' do
      it 'destroys the list' do
        expect { subject }.to change { klass.count }.by(-1)
      end

      it 'returns an empty list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('list')
        expect(mutation_response['list']).to be_nil
        expect(mutation_response['errors']).to be_empty
      end
    end

    context 'when the list is not destroyable' do
      before do
        list.update!(list_type: :backlog)
      end

      it_behaves_like 'does not destroy the list and returns an error'
    end
  end
end
