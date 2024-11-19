# frozen_string_literal: true

RSpec.shared_context 'exposing regular notes on a noteable in GraphQL' do
  include GraphqlHelpers

  let(:note) do
    create(
      :note,
      noteable: noteable,
      project: (noteable.project if noteable.respond_to?(:project))
    )
  end

  let(:user) { note.author }

  context 'for regular notes' do
    let!(:system_note) do
      create(
        :note,
        system: true,
        noteable: noteable,
        project: (noteable.project if noteable.respond_to?(:project))
      )
    end

    let(:filters) { "" }

    let(:query) do
      note_fields = <<~NOTES
      notes #{filters} {
        count
        edges {
          node {
            #{all_graphql_fields_for('Note', max_depth: 1)}
            awardEmoji {
              nodes {
                name
                user {
                  name
                }
              }
            }
          }
        }
      }
      NOTES

      noteable_query(note_fields)
    end

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    it 'includes all notes' do
      post_graphql(query, current_user: user)

      expect(noteable_data['notes']['count']).to eq(2)
      expect(noteable_data['notes']['edges'][0]['node']['body']).to eq(system_note.note)
      expect(noteable_data['notes']['edges'][1]['node']['body']).to eq(note.note)
    end

    it 'avoids N+1 queries' do
      create(:award_emoji, awardable: note, name: 'star', user: user)
      another_user = create(:user, developer_of: note.resource_parent)
      create(:note, project: note.project, noteable: noteable, author: another_user)
      note_from_external_participant = create(:note,
        project: note.project, noteable: noteable, author: Users::Internal.support_bot)
      create(:note_metadata, note: note_from_external_participant)

      post_graphql(query, current_user: user)

      control = ActiveRecord::QueryRecorder.new { post_graphql(query, current_user: user) }

      expect_graphql_errors_to_be_empty

      another_note = create(:note, project: note.project, noteable: noteable, author: user)
      create(:award_emoji, awardable: another_note, name: 'star', user: user)
      another_user = create(:user, developer_of: note.resource_parent)
      note_with_different_user = create(:note, project: note.project, noteable: noteable, author: another_user)
      create(:award_emoji, awardable: note_with_different_user, name: 'star', user: user)
      another_note_from_external_participant = create(:note,
        project: note.project, noteable: noteable, author: Users::Internal.support_bot)
      create(:note_metadata, note: another_note_from_external_participant)

      expect { post_graphql(query, current_user: user) }.not_to exceed_query_limit(control)
      expect_graphql_errors_to_be_empty
    end

    context 'when filter is provided' do
      context 'when filter is set to ALL_NOTES' do
        let(:filters) { "(filter: ALL_NOTES)" }

        it 'returns all the notes' do
          post_graphql(query, current_user: user)

          expect(noteable_data['notes']['count']).to eq(2)
          expect(noteable_data['notes']['edges'][0]['node']['body']).to eq(system_note.note)
          expect(noteable_data['notes']['edges'][1]['node']['body']).to eq(note.note)
        end
      end

      context 'when filter is set to ONLY_COMMENTS' do
        let(:filters) { "(filter: ONLY_COMMENTS)" }

        it 'returns only the comments' do
          post_graphql(query, current_user: user)

          expect(noteable_data['notes']['count']).to eq(1)
          expect(noteable_data['notes']['edges'][0]['node']['body']).to eq(note.note)
        end
      end

      context 'when filter is set to ONLY_ACTIVITY' do
        let(:filters) { "(filter: ONLY_ACTIVITY)" }

        it 'returns only the activity notes' do
          post_graphql(query, current_user: user)

          expect(noteable_data['notes']['count']).to eq(1)
          expect(noteable_data['notes']['edges'][0]['node']['body']).to eq(system_note.note)
        end
      end
    end
  end

  context "for discussions" do
    let(:query) do
      discussion_fields = <<~DISCUSSIONS
      discussions {
        edges {
          node {
            #{all_graphql_fields_for('Discussion', max_depth: 4, excluded: ['productAnalyticsState'])}
          }
        }
      }
      DISCUSSIONS

      noteable_query(discussion_fields)
    end

    let!(:reply) { create(:note, noteable: noteable, in_reply_to: note, discussion_id: note.discussion_id) }

    it_behaves_like 'a working graphql query' do
      before do
        post_graphql(query, current_user: user)
      end
    end

    it 'includes all discussion notes' do
      post_graphql(query, current_user: user)

      discussion = noteable_data['discussions']['edges'].first['node']
      ids = discussion['notes']['edges'].map { |note_edge| note_edge['node']['id'] }

      expect(ids).to eq([note.to_global_id.to_s, reply.to_global_id.to_s])
    end
  end
end
