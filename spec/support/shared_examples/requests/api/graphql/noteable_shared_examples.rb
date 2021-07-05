# frozen_string_literal: true

# Requires `query(fields)`, `path_to_noteable`, `project`, and `noteable` bindings
RSpec.shared_examples 'a noteable graphql type we can query' do
  let(:note_factory) { :note }
  let(:discussion_factory) { :discussion_note }

  describe '.discussions' do
    let(:fields) do
      "discussions { nodes { #{all_graphql_fields_for('Discussion')} } }"
    end

    def expected
      noteable.discussions.map do |discussion|
        include(
          'id' => global_id_of(discussion),
          'replyId' => global_id_of(discussion, id: discussion.reply_id),
          'createdAt' => discussion.created_at.iso8601,
          'notes' => include(
            'nodes' => have_attributes(size: discussion.notes.size)
          )
        )
      end
    end

    it 'can fetch discussions' do
      create(discussion_factory, project: project, noteable: noteable)

      post_graphql(query(fields), current_user: current_user)

      expect(graphql_data_at(*path_to_noteable, :discussions, :nodes))
        .to match_array(expected)
    end

    it 'can fetch discussion noteable' do
      create(discussion_factory, project: project, noteable: noteable)
      fields =
        <<-QL.strip_heredoc
          discussions {
            nodes {
              noteable {
                __typename
                ... on #{noteable.class.name.demodulize} {
                  id
                }
              }
            }
          }
        QL

      post_graphql(query(fields), current_user: current_user)

      data = graphql_data_at(*path_to_noteable, :discussions, :nodes, :noteable, :id)
      expect(data[0]).to eq(global_id_of(noteable))
    end
  end

  describe '.notes' do
    let(:fields) do
      "notes { nodes { #{all_graphql_fields_for('Note', max_depth: 2)} } }"
    end

    def expected
      noteable.notes.map do |note|
        include(
          'id' => global_id_of(note),
          'project' => include('id' => global_id_of(project)),
          'author' => include('id' => global_id_of(note.author)),
          'createdAt' => note.created_at.iso8601,
          'body' => eq(note.note)
        )
      end
    end

    it 'can fetch notes' do
      create(note_factory, project: project, noteable: noteable)

      post_graphql(query(fields), current_user: current_user)

      expect(graphql_data_at(*path_to_noteable, :notes, :nodes))
        .to match_array(expected)
    end
  end
end
