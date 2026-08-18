# frozen_string_literal: true

require Rails.root.join('tooling/graphql/docs/schema/concerns/deprecable')

RSpec.shared_examples Tooling::Graphql::Docs::Schema::Deprecable do
  context 'when schema item is experimental' do
    subject(:deprecable) { experimental_item }

    it 'has correct properties' do
      expect(deprecable).to have_attributes(
        experiment?: true,
        deprecated?: false,
        deprecation: kind_of(Gitlab::Graphql::Deprecations::Deprecation)
      )
    end
  end

  context 'when schema item is deprecated' do
    subject(:deprecable) { deprecated_item }

    it 'has correct properties' do
      expect(deprecable).to have_attributes(
        experiment?: false,
        deprecated?: true,
        deprecation: kind_of(Gitlab::Graphql::Deprecations::Deprecation)
      )
    end
  end
end
