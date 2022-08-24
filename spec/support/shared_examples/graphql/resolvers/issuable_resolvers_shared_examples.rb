# frozen_string_literal: true

# Requires `parent`, issuable1`, `issuable2`, `issuable3`, `issuable4`,
# `finder_class` and `optimization_param` bindings.
RSpec.shared_examples 'graphql query for searching issuables' do
  it 'uses search optimization' do
    expected_arguments = a_hash_including(
      search: 'text',
      optimization_param => true
    )
    expect(finder_class).to receive(:new).with(anything, expected_arguments).and_call_original

    resolve_issuables(search: 'text')
  end

  it 'filters issuables by title' do
    issuables = resolve_issuables(search: 'created')

    expect(issuables).to contain_exactly(issuable1, issuable2)
  end

  it 'filters issuables by description' do
    issuables = resolve_issuables(search: 'text')

    expect(issuables).to contain_exactly(issuable2, issuable3)
  end

  context 'with in param' do
    it 'generates an error if param search is missing' do
      error_message = "`search` should be present when including the `in` argument"

      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) do
        resolve_issuables(in: ['title'])
      end
    end

    it 'filters issuables by title and description' do
      issuable4.update!(title: 'fourth text')
      issuables = resolve_issuables(search: 'text', in: %w[title description])

      expect(issuables).to contain_exactly(issuable2, issuable3, issuable4)
    end

    it 'filters issuables by description only' do
      with_text = resolve_issuables(search: 'text', in: ['description'])
      with_created = resolve_issuables(search: 'created', in: ['description'])

      expect(with_created).to be_empty
      expect(with_text).to contain_exactly(issuable2, issuable3)
    end

    it 'filters issuables by title only' do
      with_text = resolve_issuables(search: 'text', in: ['title'])
      with_created = resolve_issuables(search: 'created', in: ['title'])

      expect(with_created).to contain_exactly(issuable1, issuable2)
      expect(with_text).to be_empty
    end
  end

  context 'with anonymous user' do
    let_it_be(:current_user) { nil }

    context 'with disable_anonymous_search as `true`' do
      before do
        stub_feature_flags(disable_anonymous_search: true)
      end

      it 'returns an error' do
        error_message = "User must be authenticated to include the `search` argument."

        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, error_message) do
          resolve_issuables(search: 'created')
        end
      end

      it 'does not return error if search term is not present' do
        expect(resolve_issuables).not_to be_instance_of(Gitlab::Graphql::Errors::ArgumentError)
      end
    end

    context 'with disable_anonymous_search as `false`' do
      before do
        stub_feature_flags(disable_anonymous_search: false)
        parent.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
      end

      it 'filters issuables by search term' do
        issuables = resolve_issuables(search: 'created')

        expect(issuables).to contain_exactly(issuable1, issuable2)
      end
    end
  end

  def resolve_issuables(args = {}, obj = parent, context = { current_user: current_user })
    resolve(described_class, obj: obj, args: args, ctx: context, arg_style: :internal)
  end
end
