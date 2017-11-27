require 'spec_helper'

describe Search::SnippetService do
  let(:author) { create(:author) }
  let(:project) { create(:project, :public) }

  let!(:public_snippet)   { create(:snippet, :public, content: 'password: XXX') }
  let!(:internal_snippet) { create(:snippet, :internal, content: 'password: XXX') }
  let!(:private_snippet)  { create(:snippet, :private, content: 'password: XXX', author: author) }

  let!(:project_public_snippet)   { create(:snippet, :public, project: project, content: 'password: XXX') }
  let!(:project_internal_snippet) { create(:snippet, :internal, project: project, content: 'password: XXX') }
  let!(:project_private_snippet)  { create(:snippet, :private, project: project, content: 'password: XXX') }

  describe '#execute' do
    context 'unauthenticated' do
      it 'returns public snippets only' do
        search = described_class.new(nil, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, project_public_snippet]
      end
    end

    context 'authenticated' do
      it 'returns only public & internal snippets for regular users' do
        user = create(:user)
        search = described_class.new(user, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet]
      end

      it 'returns public, internal snippets and project private snippets for project members' do
        member = create(:user)
        project.team << [member, :developer]
        search = described_class.new(member, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
      end

      it 'returns public, internal and private snippets where user is the author' do
        search = described_class.new(author, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet]
      end

      it 'returns all snippets when user is admin' do
        admin = create(:admin)
        search = described_class.new(admin, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet, private_snippet, project_public_snippet, project_internal_snippet, project_private_snippet]
      end
    end
  end
end
