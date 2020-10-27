# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalSnippet do
  describe '#embeddable?' do
    [
      { snippet: :public,   embeddable: true },
      { snippet: :internal, embeddable: false },
      { snippet: :private,  embeddable: false }
    ].each do |combination|
      it 'returns true when snippet is public' do
        snippet = build(:personal_snippet, combination[:snippet])

        expect(snippet.embeddable?).to eq(combination[:embeddable])
      end
    end
  end

  it_behaves_like 'model with repository' do
    let_it_be(:container) { create(:personal_snippet, :repository) }
    let(:stubbed_container) { build_stubbed(:personal_snippet) }
    let(:expected_full_path) { "snippets/#{container.id}" }
    let(:expected_web_url_path) { "-/snippets/#{container.id}" }
  end

  describe '#parent_user' do
    it 'returns the snippet author' do
      snippet = build(:personal_snippet)

      expect(snippet.parent_user).to eq(snippet.author)
    end
  end
end
