# frozen_string_literal: true

RSpec.shared_examples 'graphql on a read-only GitLab instance' do
  include GraphqlHelpers

  context 'mutations' do
    let(:current_user) { note.author }
    let!(:note) { create(:note) }

    let(:mutation) do
      variables = {
        id: GitlabSchema.id_from_object(note).to_s
      }

      graphql_mutation(:destroy_note, variables)
    end

    it 'disallows the query' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(json_response['errors'].first['message']).to eq(Mutations::BaseMutation::ERROR_MESSAGE)
    end

    it 'does not destroy the Note' do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { Note.count }
    end
  end

  context 'read-only queries' do
    let(:current_user) { create(:user) }
    let(:project) { create(:project, :repository) }

    before do
      project.add_developer(current_user)
    end

    it 'allows the query' do
      query = graphql_query_for('project', 'fullPath' => project.full_path)

      post_graphql(query, current_user: current_user)

      expect(graphql_data['project']).not_to be_nil
    end
  end
end
