# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting notes for a merge request', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:noteable) { create(:merge_request) }
  let(:noteable_data) { graphql_data['project']['mergeRequest'] }

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

    context 'the truncated diff lines of the diff discussion' do
      let(:query) do
        noteable_query(
          <<~DISCUSSIONS
          discussions {
            nodes {
              truncatedDiffLines {
                type
                oldLine
                newLine
                text
                richText
              }
            }
          }
          DISCUSSIONS
        )
      end

      it 'includes the highlighted diff lines above the note', :aggregate_failures do
        post_graphql(query, current_user: user)

        lines = noteable_data['discussions']['nodes']
          .filter_map { |node| node['truncatedDiffLines'] }
          .find(&:present?)

        expect(lines).to be_present

        last_line = lines.last
        expect(last_line['newLine']).to eq(note.position.new_line)
        expect(last_line['type']).to eq('new')
        expect(last_line['text']).to be_present
        expect(last_line['richText']).to be_present
      end
    end

    context 'with multiple diff discussions on different files' do
      let!(:second_note) do
        create(:diff_note_on_merge_request, noteable: noteable, project: project,
          position: build(:text_diff_position, :added, file: 'files/ruby/regex.rb', new_line: 22,
            diff_refs: noteable.diff_refs))
      end

      let(:query) do
        noteable_query(
          <<~DISCUSSIONS
          discussions {
            nodes {
              truncatedDiffLines {
                newLine
                richText
              }
            }
          }
          DISCUSSIONS
        )
      end

      it 'resolves the highlighted diff lines for every diff discussion' do
        post_graphql(query, current_user: user)

        diff_line_sets = noteable_data['discussions']['nodes']
          .filter_map { |node| node['truncatedDiffLines'] }
          .select(&:present?)

        expect(diff_line_sets.size).to eq(2)
      end
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
