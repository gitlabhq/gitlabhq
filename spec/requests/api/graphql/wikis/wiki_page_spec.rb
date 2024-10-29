# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a wiki page', feature_category: :wiki do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :private, developers: user) }

  let(:slug) { wiki_page_meta.slugs.first.slug }
  let(:global_id) { wiki_page_meta.to_gid.to_s }
  let(:current_user) { user }

  let(:query) do
    graphql_query_for(:wiki_page, { 'slug' => slug, 'project_id' => global_id_of(project) }, wiki_page_fields)
  end

  let(:wiki_page_fields) { all_graphql_fields_for('WikiPage', max_depth: 2) }
  let(:wiki_page_data) { graphql_data_at('wikiPage') }

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'for project wikis' do
    let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page, container: project) }

    it_behaves_like 'a working graphql query that returns data'

    it 'returns all fields' do
      expect(wiki_page_data).to include(
        'id' => global_id,
        'title' => wiki_page_meta.title,
        'userPermissions' => {
          'readWikiPage' => true,
          'createNote' => true
        }
      )
    end

    context 'when page does not exist' do
      let(:slug) { 'foobar' }

      it_behaves_like 'a working graphql query that returns no data'
    end

    context 'when user is not a member' do
      let_it_be(:other_user) { create(:user) }

      let(:current_user) { other_user }

      it_behaves_like 'a working graphql query that returns no data'
    end

    describe 'notes' do
      let_it_be(:note) { create(:note, noteable: wiki_page_meta, author: user, project: project) }

      let(:notes_response) do
        graphql_data_at(:wiki_page, :notes, :nodes)
      end

      let(:wiki_page_fields) do
        <<~GRAPHQL
          notes {
            nodes {
              #{all_graphql_fields_for('Note', max_depth: 2)}
            }
          }
        GRAPHQL
      end

      it 'returns notes' do
        expect(notes_response).to contain_exactly(
          a_graphql_entity_for(note)
        )
      end
    end

    describe 'discussions' do
      let_it_be(:discussion) do
        create(:discussion_note_on_wiki_page, noteable: wiki_page_meta, author: user, project: project).to_discussion
      end

      let(:discussions_response) do
        graphql_data_at(:wiki_page, :discussions, :nodes)
      end

      let(:wiki_page_fields) do
        <<~GRAPHQL
          discussions {
            nodes {
              #{all_graphql_fields_for('Discussion', max_depth: 2)}
            }
          }
        GRAPHQL
      end

      it 'returns discussions' do
        expect(discussions_response).to contain_exactly(
          a_graphql_entity_for(discussion)
        )
      end
    end
  end
end
