require 'spec_helper'

describe Search::SnippetService, services: true do
  let(:author) { create(:author) }
  let(:internal_user) { create(:user) }

  let!(:public_snippet)   { create(:snippet, :public, content: 'password: XXX') }
  let!(:internal_snippet) { create(:snippet, :internal, content: 'password: XXX') }
  let!(:private_snippet)  { create(:snippet, :private, content: 'password: XXX', author: author) }

  describe '#execute' do
    context 'unauthenticated' do
      it 'should return public snippets only' do
        search = described_class.new(nil, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet]
      end
    end

    context 'authenticated' do
      it 'should return only public & internal snippets' do
        search = described_class.new(internal_user, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet]
      end

      it 'should return public, internal and private snippets for author' do
        search = described_class.new(author, search: 'password')
        results = search.execute

        expect(results.objects('snippet_blobs')).to match_array [public_snippet, internal_snippet, private_snippet]
      end
    end
  end
end
