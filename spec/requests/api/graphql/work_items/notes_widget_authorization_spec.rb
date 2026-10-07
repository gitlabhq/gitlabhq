# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.workItem notes widget authorization', :with_current_organization,
  feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:public_group) { create(:group, :public) }
  let_it_be(:public_project) { create(:project, :public, group: public_group) }
  let_it_be(:developer) { create(:user, developer_of: public_group) }

  let_it_be(:public_work_item) { create(:work_item, project: public_project) }

  let_it_be(:public_note) do
    create(:discussion_note_on_issue, noteable: public_work_item, project: public_project,
      author: developer, note: 'public comment')
  end

  let_it_be(:internal_note) do
    create(:discussion_note_on_issue, noteable: public_work_item, project: public_project,
      author: developer, confidential: true, note: 'internal comment body')
  end

  let(:current_user) { nil }

  describe 'workItem -> widgets.notes.discussions -> noteable -> discussions -> notes traversal' do
    let(:query) do
      graphql_query_for(
        'workItem',
        { 'id' => public_work_item.to_gid.to_s },
        <<~FIELDS
          widgets {
            ... on WorkItemWidgetNotes {
              discussions {
                nodes {
                  noteable {
                    ... on Issue {
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
            }
          }
        FIELDS
      )
    end

    def leaf_notes
      widgets = graphql_data.dig('workItem', 'widgets') || []
      outer = widgets.find { |w| w.key?('discussions') }
      return [] unless outer

      outer['discussions']['nodes'].flat_map do |d|
        inner = d.dig('noteable', 'discussions', 'nodes') || []
        inner.flat_map { |n| n['notes']['nodes'] }
      end
    end

    context 'when the requester is anonymous' do
      it 'does not disclose internal note bodies' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).not_to include(a_string_including('internal comment body'))
      end
    end

    context 'when the requester is a non-member user' do
      let(:current_user) { create(:user) }

      it 'does not disclose internal note bodies' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).not_to include(a_string_including('internal comment body'))
      end
    end

    context 'when the requester is a developer' do
      let(:current_user) { developer }

      it 'sees both public and internal notes' do
        post_graphql(query, current_user: current_user)

        bodies = leaf_notes.pluck('body').compact
        expect(bodies).to include(a_string_including('public comment'))
        expect(bodies).to include(a_string_including('internal comment body'))
      end
    end
  end
end
