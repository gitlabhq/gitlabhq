# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Repositioning an ImageDiffNote', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:noteable) { create(:merge_request) }
  let_it_be(:project) { noteable.project }

  let(:note) { create(:image_diff_note_on_merge_request, noteable: noteable, project: project) }
  let(:new_position) { { x: 10 } }
  let(:current_user) { project.creator }

  let(:mutation_variables) do
    {
      id: global_id_of(note),
      position: new_position
    }
  end

  let(:mutation) do
    graphql_mutation(:reposition_image_diff_note, mutation_variables) do
      <<~QL
        note {
          id
        }
        errors
      QL
    end
  end

  def mutation_response
    graphql_mutation_response(:reposition_image_diff_note)
  end

  it 'updates the note', :aggregate_failures do
    expect do
      post_graphql_mutation(mutation, current_user: current_user)
    end.to change { note.reset.position.x }.to(10)

    expect(mutation_response['note']).to match a_graphql_entity_for(note)
    expect(mutation_response['errors']).to be_empty
  end

  context 'when the note is not a DiffNote' do
    let(:note) { project }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/does not represent an instance of DiffNote/) }
    end
  end

  context 'when a position arg is nil' do
    let(:new_position) { { x: nil, y: 10 } }

    it 'does not set the property to nil', :aggregate_failures do
      expect do
        post_graphql_mutation(mutation, current_user: current_user)
      end.not_to change { note.reset.position.x }

      expect(mutation_response['note']).to match a_graphql_entity_for(note)
      expect(mutation_response['errors']).to be_empty
    end
  end

  context 'when all position args are nil' do
    let(:new_position) { { x: nil } }

    it_behaves_like 'a mutation that returns top-level errors' do
      let(:match_errors) { include(/At least one property of `UpdateDiffImagePositionInput` must be set/) }
    end
  end
end
