# frozen_string_literal: true

RSpec.shared_context 'exposing regular notes on a noteable in GraphQL' do
  include GraphqlHelpers

  let(:note) do
    create(:note,
           noteable: noteable,
           project: (noteable.project if noteable.respond_to?(:project)))
  end

  let(:user) { note.author }

  context 'for regular notes' do
    let(:query) do
      note_fields = <<~NOTES
      notes {
        edges {
          node {
            #{all_graphql_fields_for('Note', max_depth: 1)}
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

    it 'includes the note' do
      post_graphql(query, current_user: user)

      expect(noteable_data['notes']['edges'].first['node']['body'])
        .to eq(note.note)
    end
  end

  context "for discussions" do
    let(:query) do
      discussion_fields = <<~DISCUSSIONS
      discussions {
        edges {
          node {
            #{all_graphql_fields_for('Discussion', max_depth: 4)}
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
