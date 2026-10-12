# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.mergeRequest discussionsWithActivity authorization',
  feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:public_project) { create(:project, :public, :empty_repo) }
  let_it_be(:developer) { create(:user, developer_of: public_project) }

  let_it_be(:merge_request, freeze: false) { create(:merge_request, source_project: public_project) }

  let_it_be(:public_note) do
    create(:discussion_note_on_merge_request, noteable: merge_request, project: public_project,
      author: developer, note: 'public mr comment')
  end

  let_it_be(:internal_note) do
    create(:discussion_note_on_merge_request, noteable: merge_request, project: public_project,
      author: developer, confidential: true, note: 'internal mr comment body')
  end

  let(:current_user) { nil }

  describe 'mergeRequest -> discussionsWithActivity -> noteable -> discussions -> notes traversal' do
    let(:query) do
      graphql_query_for(
        'mergeRequest',
        { 'id' => merge_request.to_gid.to_s },
        <<~FIELDS
          discussionsWithActivity {
            nodes {
              noteable {
                ... on MergeRequest {
                  discussions {
                    nodes {
                      notes {
                        nodes {
                          id
                          internal
                          body
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        FIELDS
      )
    end

    def leaf_notes
      outer = graphql_data.dig('mergeRequest', 'discussionsWithActivity', 'nodes') || []
      outer.flat_map do |d|
        inner = d.dig('noteable', 'discussions', 'nodes') || []
        inner.flat_map { |n| n['notes']['nodes'] }
      end
    end

    context 'when the requester is anonymous' do
      it 'does not disclose internal note bodies' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).not_to include(a_string_including('internal mr comment body'))
      end
    end

    context 'when the requester is a non-member user' do
      let(:current_user) { create(:user) }

      it 'does not disclose internal note bodies' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).not_to include(a_string_including('internal mr comment body'))
      end
    end

    context 'when the requester is a developer' do
      let(:current_user) { developer }

      it 'sees both public and internal notes' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).to include(a_string_including('public mr comment'))
        expect(bodies).to include(a_string_including('internal mr comment body'))
      end
    end
  end
end
