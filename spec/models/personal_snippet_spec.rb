# frozen_string_literal: true

require 'spec_helper'

describe PersonalSnippet do
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
end
