# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Graphql::MarkdownField do
  include Gitlab::Routing
  include GraphqlHelpers

  describe '.markdown_field' do
    it 'creates the field with some default attributes' do
      field = class_with_markdown_field(:test_html, null: true, method: :hello).fields['testHtml']

      expect(field.name).to eq('testHtml')
      expect(field.description).to eq('GitLab Flavored Markdown rendering of `hello`')
      expect(field.type).to eq(GraphQL::Types::String)
      expect(field.complexity).to eq(5)
    end

    context 'developer warnings' do
      let_it_be(:expected_error) { /Only `method` is allowed to specify the markdown field/ }

      it 'raises when passing a resolver' do
        expect { class_with_markdown_field(:test_html, null: true, resolver: 'not really') }
          .to raise_error(expected_error)
      end
    end

    context 'resolving markdown' do
      let_it_be(:note) { build(:note, note: '# Markdown!') }
      let_it_be(:expected_markdown) { '<h1 data-sourcepos="1:1-1:11" dir="auto">Markdown!</h1>' }
      let_it_be(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
      let_it_be(:context) { GraphQL::Query::Context.new(query: query, values: {}) }

      let(:type_class) { class_with_markdown_field(:note_html, null: false) }
      let(:type_instance) { type_class.authorized_new(note, context) }
      let(:field) { type_class.fields['noteHtml'] }

      it 'renders markdown from the same property as the field name without the `_html` suffix' do
        expect(field.resolve(type_instance, {}, context)).to eq(expected_markdown)
      end

      context 'when a `method` argument is passed' do
        let(:type_class) { class_with_markdown_field(:test_html, null: false, method: :note) }
        let(:field) { type_class.fields['testHtml'] }

        it 'renders markdown from a specific property' do
          expect(field.resolve(type_instance, {}, context)).to eq(expected_markdown)
        end
      end

      context 'when a block is passed for the resolved object' do
        let(:type_class) do
          class_with_markdown_field(:note_html, null: false) do |resolved_object|
            resolved_object.object
          end
        end

        let(:type_instance) { type_class.authorized_new(class_wrapped_object(note), context) }

        it 'renders markdown from the same property as the field name without the `_html` suffix' do
          expect(field.resolve(type_instance, {}, context)).to eq(expected_markdown)
        end
      end

      describe 'basic verification that references work' do
        let_it_be(:project) { create(:project, :public) }

        let(:issue) { create(:issue, project: project) }
        let(:note) { build(:note, note: "Referencing #{issue.to_reference(full: true)}") }

        it 'renders markdown correctly' do
          expect(field.resolve(type_instance, {}, context)).to include(issue_path(issue))
        end

        context 'when the issue is not publicly accessible' do
          let_it_be(:project) { create(:project, :private) }

          it 'hides the references from users that are not allowed to see the reference' do
            expect(field.resolve(type_instance, {}, context)).not_to include(issue_path(issue))
          end

          it 'shows the reference to users that are allowed to see it' do
            context = GraphQL::Query::Context.new(query: query, values: { current_user: project.first_owner })
            type_instance = type_class.authorized_new(note, context)

            expect(field.resolve(type_instance, {}, context)).to include(issue_path(issue))
          end
        end
      end
    end
  end

  def class_with_markdown_field(name, **args, &blk)
    Class.new(Types::BaseObject) do
      prepend Gitlab::Graphql::MarkdownField
      graphql_name 'MarkdownFieldTest'

      markdown_field name, **args, &blk
    end
  end

  def class_wrapped_object(object)
    Class.new do
      def initialize(object)
        @object = object
      end

      attr_accessor :object
    end.new(object)
  end
end
