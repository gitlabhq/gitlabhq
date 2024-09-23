# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::UsernameMentionRewriter, feature_category: :importers do
  let(:klass) { Class.new { include Gitlab::Import::UsernameMentionRewriter } }
  let(:instance) { klass.new }

  describe '#update_username_mentions' do
    let(:original_text) { 'The @cat jumped on the @mat!' }
    let(:expected_text) { 'The `@cat` jumped on the `@mat`!' }

    context 'when the relation hash has a description and a note' do
      let(:relation_hash) { { 'description' => original_text, 'note' => original_text } }

      it 'wraps @usernames in backticks' do
        instance.update_username_mentions(relation_hash)

        expect(relation_hash['description']).to eq(expected_text)
        expect(relation_hash['note']).to eq(expected_text)
      end
    end

    context 'when the relation hash does not have a description or a note' do
      let(:relation_hash) { { 'name' => original_text, 'path' => original_text } }

      it 'does not wrap @usernames in backticks' do
        instance.update_username_mentions(relation_hash)

        expect(relation_hash['name']).to eq(original_text)
        expect(relation_hash['path']).to eq(original_text)
      end
    end
  end

  describe '#wrap_mentions_in_backticks' do
    context 'when text is nil' do
      it 'returns nil' do
        expect(instance.wrap_mentions_in_backticks(nil)).to be_nil
      end
    end

    context 'when the text is empty' do
      it 'returns an empty string' do
        expect(instance.wrap_mentions_in_backticks('')).to eq('')
      end
    end

    context 'when the text contains username mentions' do
      let(:original_text) { "I said to @sam_allen.greg the code should follow @bob's advice. @.ali-ce/group#9?" }
      let(:expected_text) { "I said to `@sam_allen.greg` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }

      it 'wraps them in backticks preserving punctuation' do
        expect(instance.wrap_mentions_in_backticks(original_text)).to eq(expected_text)
      end
    end

    context 'when the text contains code-formatted text' do
      let(:original_text) do
        "I said to @sam the code should be ``find @bob and return`` " \
          "and he said no it's ```find @bob and play```. " \
          "What do you think @alice? " \
          "Another alternative is `forward to the @goonsquad!`"
      end

      let(:expected_text) do
        "I said to `@sam` the code should be ``find @bob and return`` " \
          "and he said no it's ```find @bob and play```. " \
          "What do you think `@alice`? " \
          "Another alternative is `forward to the @goonsquad!`"
      end

      it 'wraps username mentions only if they are outside code-formatted text' do
        expect(instance.wrap_mentions_in_backticks(original_text)).to eq(expected_text)
      end
    end

    context 'when the text contains email addresses or urls' do
      let(:original_text) do
        "@rodeo rudolph@xmas.com Signed-off-by: Some Name <somename@gmail.com> " \
          "Visit https://docs.example.com/en/some-server@3.5/admin/xxx/abcd/xxxx " \
          "@boulder Sounds good (@knejad what do you think?)"
      end

      let(:expected_text) do
        "`@rodeo` rudolph@xmas.com Signed-off-by: Some Name <somename@gmail.com> " \
          "Visit https://docs.example.com/en/some-server@3.5/admin/xxx/abcd/xxxx " \
          "`@boulder` Sounds good (`@knejad` what do you think?)"
      end

      it 'does not insert backticks before @ characters' do
        expect(instance.wrap_mentions_in_backticks(original_text)).to eq(expected_text)
      end
    end
  end
end
