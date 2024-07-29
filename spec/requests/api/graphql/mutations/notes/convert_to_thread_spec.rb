# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Notes::ConvertToThread, feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:noteable) { create(:work_item) }

  let(:project) { noteable.project }
  let(:current_user) { noteable.author }
  let(:note) { create(:note, noteable: noteable, project: project) }

  let(:mutation) do
    graphql_mutation(:note_convert_to_thread, { id: global_id_of(note) }) do
      <<~QL
        note {
          id
          resolvable
        }
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:note_convert_to_thread)
  end

  it 'converts to resolvable thread' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response['note']).to match a_graphql_entity_for(note.becomes!(DiscussionNote))
    expect(mutation_response.dig('note', 'resolvable')).to eq(true)
    expect(mutation_response['errors']).to be_empty
  end

  context 'when discussion note is given' do
    let(:note) { create(:discussion_note, noteable: noteable, project: project) }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/Note cannot be converted to a resolvable thread/) }
    end
  end

  context 'when noteable does not support resolvable notes' do
    let(:noteable) { create(:project_snippet) }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/Note cannot be converted to a resolvable thread/) }
    end
  end

  context 'when note is internal and user does not have access' do
    let(:current_user) { create(:user, guest_of: project) }
    let(:note) { create(:note, :internal, noteable: noteable, project: project) }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/you don't have permission to perform this action/) }
    end
  end

  context 'when saving fails with validation error' do
    before do
      note.update_column(:project_id, nil)
    end

    it 'returns the validation error' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['errors']).to include("Project can't be blank")
    end
  end
end
