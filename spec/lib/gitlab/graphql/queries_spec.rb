# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Queries do
  shared_examples 'a valid GraphQL query for the blog schema' do
    it 'is valid' do
      expect(subject.validate(schema).second).to be_empty
    end
  end

  shared_examples 'an invalid GraphQL query for the blog schema' do
    it 'is invalid' do
      expect(subject.validate(schema).second).to match errors
    end
  end

  # Toy schema to validate queries against
  let_it_be(:schema) do
    author = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Author'
      field :name, GraphQL::Types::String, null: true
      field :handle, GraphQL::Types::String, null: false
      field :verified, GraphQL::Types::Boolean, null: false
    end

    post = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Post'
      field :name, GraphQL::Types::String, null: false
      field :title, GraphQL::Types::String, null: false
      field :content, GraphQL::Types::String, null: true
      field :author, author, null: false
    end
    author.field :posts, [post], null: false do
      argument :blog_title, GraphQL::Types::String, required: false
    end

    blog = Class.new(GraphQL::Schema::Object) do
      graphql_name 'Blog'
      field :title, GraphQL::Types::String, null: false
      field :description, GraphQL::Types::String, null: false
      field :main_author, author, null: false
      field :posts, [post], null: false
      field :post, post, null: true do
        argument :slug, GraphQL::Types::String, required: true
      end
    end

    Class.new(GraphQL::Schema) do
      query(Class.new(GraphQL::Schema::Object) do
        graphql_name 'Query'
        field :blog, blog, null: true do
          argument :title, GraphQL::Types::String, required: true
        end
        field :post, post, null: true do
          argument :slug, GraphQL::Types::String, required: true
        end
      end)
    end
  end

  let(:root) do
    Rails.root / 'fixtures/lib/gitlab/graphql/queries'
  end

  describe Gitlab::Graphql::Queries::Fragments do
    subject { described_class.new(root) }

    it 'has the right home' do
      expect(subject.home).to eq (root / 'app/assets/javascripts').to_s
    end

    it 'has the right EE home' do
      expect(subject.home_ee).to eq (root / 'ee/app/assets/javascripts').to_s
    end

    it 'caches query definitions' do
      fragment = subject.get('foo')

      expect(fragment).to be_a(::Gitlab::Graphql::Queries::Definition)
      expect(subject.get('foo')).to be fragment
    end
  end

  describe '.all' do
    it 'is the combination of finding queries in CE and EE' do
      expect(described_class)
        .to receive(:find).with(Rails.root / 'app/assets/javascripts').and_return([:ce_assets])
      expect(described_class)
        .to receive(:find).with(Rails.root / 'ee/app/assets/javascripts').and_return([:ee_assets])
      expect(described_class)
        .to receive(:find).with(Rails.root / 'app/graphql/queries').and_return([:ce_gql])
      expect(described_class)
        .to receive(:find).with(Rails.root / 'ee/app/graphql/queries').and_return([:ee_gql])

      expect(described_class.all).to contain_exactly(:ce_assets, :ee_assets, :ce_gql, :ee_gql)
    end
  end

  describe '.find' do
    def definition_of(path)
      be_a(::Gitlab::Graphql::Queries::Definition)
        .and(have_attributes(file: path.to_s))
    end

    it 'find a single specific file' do
      path = root / 'post_by_slug.graphql'

      expect(described_class.find(path)).to contain_exactly(definition_of(path))
    end

    it 'ignores files that do not exist' do
      path = root / 'not_there.graphql'

      expect(described_class.find(path)).to be_empty
    end

    it 'ignores fragments' do
      path = root / 'author.fragment.graphql'

      expect(described_class.find(path)).to be_empty
    end

    it 'ignores typedefs' do
      path = root / 'typedefs.graphql'

      expect(described_class.find(path)).to be_empty
    end

    it 'finds all query definitions under a root directory' do
      found = described_class.find(root)

      expect(found).to include(
        definition_of(root / 'post_by_slug.graphql'),
        definition_of(root / 'post_by_slug.with_import.graphql'),
        definition_of(root / 'post_by_slug.with_import.misspelled.graphql'),
        definition_of(root / 'duplicate_imports.graphql'),
        definition_of(root / 'deeply/nested/query.graphql')
      )

      expect(found).not_to include(
        definition_of(root / 'typedefs.graphql'),
        definition_of(root / 'author.fragment.graphql')
      )
    end
  end

  describe Gitlab::Graphql::Queries::Definition do
    let(:fragments) { Gitlab::Graphql::Queries::Fragments.new(root, '.') }

    subject { described_class.new(root / path, fragments) }

    context 'a simple query' do
      let(:path) { 'post_by_slug.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'has a complexity' do
        expect(subject.complexity(schema)).to be < 10
      end
    end

    context 'a query with an import' do
      let(:path) { 'post_by_slug.with_import.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a query with duplicate imports' do
      let(:path) { 'duplicate_imports.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a query importing from ee_else_ce' do
      let(:path) { 'ee_else_ce.import.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'can resolve the ee fields' do
        expect(subject.text(mode: :ce)).not_to include('verified')
        expect(subject.text(mode: :ee)).to include('verified')
      end
    end

    context 'a query refering to parent directories' do
      let(:path) { 'deeply/nested/query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a query refering to parent directories, incorrectly' do
      let(:path) { 'deeply/nested/bad_import.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            be_a(::Gitlab::Graphql::Queries::FileNotFound)
              .and(have_attributes(message: include('deeply/author.fragment.graphql')))
          )
        end
      end
    end

    context 'a query with a broken import' do
      let(:path) { 'post_by_slug.with_import.misspelled.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            be_a(::Gitlab::Graphql::Queries::FileNotFound)
              .and(have_attributes(message: include('auther.fragment.graphql')))
          )
        end
      end
    end

    context 'a query which imports a file with a broken import' do
      let(:path) { 'transitive_bad_import.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            be_a(::Gitlab::Graphql::Queries::FileNotFound)
              .and(have_attributes(message: include('does-not-exist.graphql')))
          )
        end
      end
    end

    context 'a query containing a client directive' do
      let(:path) { 'client.query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'is tagged as a client query' do
        expect(subject.validate(schema).first).to eq :client_query
      end
    end

    context 'a mixed client query, valid' do
      let(:path) { 'mixed_client.query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'is not tagged as a client query' do
        expect(subject.validate(schema).first).not_to eq :client_query
      end
    end

    context 'a mixed client query, with skipped argument' do
      let(:path) { 'mixed_client_skipped_argument.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a mixed client query, with unused fragment' do
      let(:path) { 'mixed_client_unused_fragment.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a client query, with unused fragment' do
      let(:path) { 'client_unused_fragment.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'is tagged as a client query' do
        expect(subject.validate(schema).first).to eq :client_query
      end
    end

    context 'a mixed client query, invalid' do
      let(:path) { 'mixed_client_invalid.query.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(have_attributes(message: include('titlz')))
        end
      end
    end

    context 'a query containing a connection directive' do
      let(:path) { 'connection.query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end

    context 'a query which mentions an incorrect field' do
      let(:path) { 'wrong_field.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            have_attributes(message: /'createdAt' doesn't exist/),
            have_attributes(message: /'categories' doesn't exist/)
          )
        end
      end
    end

    context 'a query which has a missing argument' do
      let(:path) { 'missing_argument.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            have_attributes(message: include('blog'))
          )
        end
      end
    end

    context 'a query which has a bad argument' do
      let(:path) { 'bad_argument.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            have_attributes(message: include('Nullability mismatch on variable $bad'))
          )
        end
      end
    end

    context 'a query which has a syntax error' do
      let(:path) { 'syntax-error.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          if GraphQL::VERSION >= Gem::Version.new('2.3.12')
            # TODO: Clean up after the following MR is merged and the graphql
            # gem is ugpraded to 2.3.12
            # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/159460
            contain_exactly(
              have_attributes(
                message: include('Expected NAME, actual: RCURLY ("}") at [1, 7]')
              )
            )
          else
            contain_exactly(
              have_attributes(
                message: include('Expected LCURLY, actual: RCURLY ("}") at [1, 7]')
              )
            )
          end
        end
      end
    end

    context 'a query which has an unused import' do
      let(:path) { 'unused_import.graphql' }

      it_behaves_like 'an invalid GraphQL query for the blog schema' do
        let(:errors) do
          contain_exactly(
            have_attributes(message: include('AuthorF was defined, but not used'))
          )
        end
      end
    end

    context 'a query containing a persist directive' do
      let(:path) { 'persist_directive.query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'

      it 'is tagged as a client query' do
        expect(subject.validate(schema).first).to eq :client_query
      end
    end

    context 'a query containing a persistantly directive' do
      let(:path) { 'persistantly_directive.query.graphql' }

      it 'is not tagged as a client query' do
        expect(subject.validate(schema).first).not_to eq :client_query
      end
    end

    context 'a query containing a persist field' do
      let(:path) { 'persist_field.query.graphql' }

      it_behaves_like 'a valid GraphQL query for the blog schema'
    end
  end
end
