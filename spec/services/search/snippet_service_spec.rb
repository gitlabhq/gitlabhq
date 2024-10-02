# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::SnippetService, feature_category: :global_search do
  let_it_be(:author) { create(:author) }
  let_it_be(:project) { create(:project, :public) }

  let_it_be(:public_snippet)   { create(:personal_snippet, :public, title: 'Foo Bar Title') }
  let_it_be(:internal_snippet) { create(:personal_snippet, :internal, title: 'Foo Bar Title') }
  let_it_be(:private_snippet)  { create(:personal_snippet, :private, title: 'Foo Bar Title', author: author) }

  let_it_be(:project_public_snippet)   { create(:project_snippet, :public, project: project, title: 'Foo Bar Title') }
  let_it_be(:project_internal_snippet) { create(:project_snippet, :internal, project: project, title: 'Foo Bar Title') }
  let_it_be(:project_private_snippet)  { create(:project_snippet, :private, project: project, title: 'Foo Bar Title') }

  let_it_be(:user) { create(:user) }

  describe '#execute' do
    context 'unauthenticated' do
      it 'returns public snippets only' do
        search = described_class.new(nil, search: 'bar')
        results = search.execute

        expect(results.objects('snippet_titles')).to match_array [public_snippet, project_public_snippet]
      end
    end

    context 'authenticated' do
      it 'returns only public & internal snippets for regular users' do
        search = described_class.new(user, search: 'bar')
        results = search.execute

        expect(results.objects('snippet_titles')).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet]
      end

      it 'returns public, internal snippets and project private snippets for project members' do
        project.add_developer(user)
        search = described_class.new(user, search: 'bar')
        results = search.execute

        expect(results.objects('snippet_titles')).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
      end

      it 'returns public, internal and private snippets where user is the author' do
        search = described_class.new(author, search: 'bar')
        results = search.execute

        expect(results.objects('snippet_titles')).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet]
      end

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns all snippets when user is admin' do
          admin = create(:admin)
          search = described_class.new(admin, search: 'bar')
          results = search.execute

          expect(results.objects('snippet_titles')).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
        end
      end

      context 'when admin mode is disabled' do
        it 'returns only public & internal snippets when user is admin' do
          admin = create(:admin)
          search = described_class.new(admin, search: 'bar')
          results = search.execute

          expect(results.objects('snippet_titles')).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet]
        end
      end
    end
  end

  describe '#scope' do
    it 'always scopes to snippet_titles' do
      search = described_class.new(user, search: 'bar')

      expect(search.scope).to eq 'snippet_titles'
    end
  end
end
