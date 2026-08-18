# frozen_string_literal: true

require 'fast_spec_helper'

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
    context 'with punctuation, whitespace, and boundary conditions' do
      using RSpec::Parameterized::TableSyntax

      where(:description, :original_text, :expected_text) do
        'nil'                                                  | nil                       | nil
        'empty string'                                         | ''                        | ''
        'username mentions'                                    | 'Hey @aa.bb thanks!'      | 'Hey `@aa.bb` thanks!'
        'mention at the very start of the string'              | '@alice said hi'          | '`@alice` said hi'
        'mention at the very end of the string'                | 'Thanks @alice'           | 'Thanks `@alice`'
        'mention followed by full stop'                        | 'hi @bob. hi @alice.'     | 'hi `@bob`. hi `@alice`.'
        'username with dots in and after'                      | 'hi @aa.bb. please check' | 'hi `@aa.bb`. please check'
        'mention followed by a comma'                          | 'cc @bob, thanks'         | 'cc `@bob`, thanks'
        'mention followed by a colon'                          | 'ping @bob: you there'    | 'ping `@bob`: you there'
        'mention followed by a semicolon'                      | 'cc @bob; thanks'         | 'cc `@bob`; thanks'
        'single-character username'                            | '@a is here'              | '`@a` is here'
        'username ending in a hyphen'                          | 'ping @foo-bar- now'      | 'ping `@foo-bar-` now'
        'username ending in a slash'                           | '@foo/bar/ test'          | '`@foo/bar/` test'
        'username ending in a hash'                            | '@foo# test'              | '`@foo#` test'
        'username consisting only of a dot is left unwrapped'  | 'email @. test'           | 'email @. test'
        'mention preceded by a tab'                            | "guests:\t@alice"         | "guests:\t`@alice`"
        'mention preceded by line break'                       | "guests:\n@alice"         | "guests:\n`@alice`"
        'mention preceded by a carriage return and linefeed'   | "guests:\r\n@alice"       | "guests:\r\n`@alice`"
        'mention immediately wrapped in parentheses'           | '(@bob)'                  | '(`@bob`)'
        'two mentions separated only by a slash'               | '@alice/@bob'             | '`@alice/``@bob`'
        'username containing uppercase letters and digits'     | '@Bob123 hi'              | '`@Bob123` hi'
        'group mention'                                        | 'maybe @.ali-ce/group#9?' | 'maybe `@.ali-ce/group#9`?'
      end

      with_them do
        it(params[:description]) do
          expect(instance.wrap_mentions_in_backticks(original_text)).to eq(expected_text)
        end
      end
    end

    context 'when the text contains code-formatted text' do
      let(:original_text) do
        <<~CODE_BLOCK
        I said to @sam the code should be

        ```
        find @bob and return
        ```
        and he said no it's ```find @bob and play```.

        What do you think @alice?

        Another alternative is `forward to the @goonsquad!`
        CODE_BLOCK
      end

      let(:expected_text) do
        <<~CODE_BLOCK
        I said to `@sam` the code should be

        ```
        find @bob and return
        ```
        and he said no it's ```find @bob and play```.

        What do you think `@alice`?

        Another alternative is `forward to the @goonsquad!`
        CODE_BLOCK
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
