# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Graphql::MarkdownField do
  describe '.markdown_field' do
    it 'creates the field with some default attributes' do
      field = class_with_markdown_field(:test_html, null: true, method: :hello).fields['testHtml']

      expect(field.name).to eq('testHtml')
      expect(field.description).to eq('The GitLab Flavored Markdown rendering of `hello`')
      expect(field.type).to eq(GraphQL::STRING_TYPE)
      expect(field.to_graphql.complexity).to eq(5)
    end

    context 'developer warnings' do
      let(:expected_error) { /Only `method` is allowed to specify the markdown field/ }

      it 'raises when passing a resolver' do
        expect { class_with_markdown_field(:test_html, null: true, resolver: 'not really') }
          .to raise_error(expected_error)
      end

      it 'raises when passing a resolve block' do
        expect { class_with_markdown_field(:test_html, null: true, resolve: -> (_, _, _) { 'not really' } ) }
          .to raise_error(expected_error)
      end
    end

    context 'resolving markdown' do
      let(:note) { build(:note, note: '# Markdown!') }
      let(:thing_with_markdown) { double('markdown thing', object: note) }
      let(:expected_markdown) { '<h1 data-sourcepos="1:1-1:11" dir="auto">Markdown!</h1>' }

      it 'renders markdown from the same property as the field name without the `_html` suffix' do
        field = class_with_markdown_field(:note_html, null: false).fields['noteHtml']

        expect(field.to_graphql.resolve(thing_with_markdown, {}, {})).to eq(expected_markdown)
      end

      it 'renders markdown from a specific property when a `method` argument is passed' do
        field = class_with_markdown_field(:test_html, null: false, method: :note).fields['testHtml']

        expect(field.to_graphql.resolve(thing_with_markdown, {}, {})).to eq(expected_markdown)
      end
    end
  end

  def class_with_markdown_field(name, **args)
    Class.new(GraphQL::Schema::Object) do
      prepend Gitlab::Graphql::MarkdownField

      markdown_field name, **args
    end
  end
end
