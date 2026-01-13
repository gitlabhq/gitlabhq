# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::TypeUnwrapper, feature_category: :permissions do
  let(:test_class) do
    Class.new do
      include Gitlab::Graphql::Authz::TypeUnwrapper

      def unwrap(type)
        unwrap_type(type)
      end
    end
  end

  let(:base_type) { Types::IssueType }

  describe '#unwrap_type' do
    subject(:unwrap_type) { test_class.new.unwrap(wrapped_type) }

    context 'with a base type' do
      let(:wrapped_type) { base_type }

      it { is_expected.to eq base_type }
    end

    context 'with a NonNull type' do
      let(:wrapped_type) { GraphQL::Schema::NonNull.new(base_type) }

      it { is_expected.to eq base_type }
    end

    context 'with a List type' do
      let(:wrapped_type) { GraphQL::Schema::List.new(base_type) }

      it { is_expected.to eq base_type }
    end

    context 'with nested wrappers' do
      let(:wrapped_type) do
        GraphQL::Schema::NonNull.new(
          GraphQL::Schema::List.new(
            GraphQL::Schema::NonNull.new(base_type)
          )
        )
      end

      it { is_expected.to eq base_type }
    end

    context 'with a Connection type' do
      let(:wrapped_type) { Types::IssueType.connection_type }

      it { is_expected.to eq base_type }
    end

    context 'with a NonNull Connection type' do
      let(:wrapped_type) do
        GraphQL::Schema::NonNull.new(Types::IssueType.connection_type)
      end

      it { is_expected.to eq base_type }
    end

    context 'with a type that has no wrappers' do
      let(:base_type) { GraphQL::Types::String }
      let(:wrapped_type) { GraphQL::Types::String }

      it { is_expected.to eq base_type }
    end
  end
end
