# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting notes for a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:noteable) { create(:merge_request) }

  def noteable_query(noteable_fields)
    <<~QRY
      {
        project(fullPath: "#{noteable.project.full_path}") {
          id
          mergeRequest(iid: "#{noteable.iid}") {
            #{noteable_fields}
          }
        }
      }
    QRY
  end
  let(:noteable_data) { graphql_data['project']['mergeRequest'] }

  it_behaves_like "exposing regular notes on a noteable in GraphQL"

  context 'diff notes on a merge request' do
    let(:project) { noteable.project }
    let!(:note) { create(:diff_note_on_merge_request, noteable: noteable, project: project) }
    let(:user) { note.author }

    let(:query) do
      noteable_query(
        <<~NOTES
        notes {
          edges {
            node {
              #{all_graphql_fields_for('Note', excluded: %w[pipeline mergeTrains])}
            }
          }
        }
      NOTES
      )
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    it 'includes the note' do
      post_graphql(query, current_user: user)

      expect(graphql_data['project']['mergeRequest']['notes']['edges'].last['node']['body'])
        .to eq(note.note)
    end

    context 'the position of the diffnote' do
      it 'includes a correct position' do
        post_graphql(query, current_user: user)

        note_data = noteable_data['notes']['edges'].last['node']

        expect(note_data['position']['positionType']).to eq('text')
        expect(note_data['position']['newLine']).to be_present
        expect(note_data['position']['x']).not_to be_present
        expect(note_data['position']['y']).not_to be_present
        expect(note_data['position']['width']).not_to be_present
        expect(note_data['position']['height']).not_to be_present
      end

      context 'with a note on an image' do
        let(:note) { create(:image_diff_note_on_merge_request, noteable: noteable, project: project) }

        it 'includes a correct position' do
          post_graphql(query, current_user: user)

          note_data = noteable_data['notes']['edges'].last['node']

          expect(note_data['position']['positionType']).to eq('image')
          expect(note_data['position']['x']).to be_present
          expect(note_data['position']['y']).to be_present
          expect(note_data['position']['width']).to be_present
          expect(note_data['position']['height']).to be_present
          expect(note_data['position']['newLine']).not_to be_present
        end
      end
    end
  end
end
