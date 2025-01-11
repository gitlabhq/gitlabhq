# frozen_string_literal: true

require "fast_spec_helper"

RSpec.describe Gitlab::Fp::Settings::SettingsDependencyResolver, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  describe '.resolve' do
    where(:description, :setting_names, :dependencies, :expected_result) do
      'empty'                | []       | {}                       | []
      'no dependencies'      | [:a]     | {}                       | [:a]
      'simple dependency'    | [:a]     | { a: [:b] }              | [:a, :b]
      'redundant dependency' | [:a, :b] | { a: [:b] }              | [:a, :b]
      'nested dependencies'  | [:a, :e] | { a: [:b, :c], c: [:d] } | [:a, :e, :b, :c, :d]
      'circular dependency'  | [:a, :e] | { a: [:b], b: [:a] }     | [:a, :e, :b]
      'nil dependency'       | [:a]     | { a: nil }               | [:a]
    end

    with_them do
      it 'resolves dependencies correctly' do
        result = described_class.resolve(setting_names, dependencies)
        expect(result).to eq(expected_result)
      end
    end
  end
end
