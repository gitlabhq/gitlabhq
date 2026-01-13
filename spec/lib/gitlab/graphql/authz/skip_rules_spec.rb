# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::SkipRules, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let(:field_type) { GraphQL::Types::String }
  let(:owner) { Types::IssueType }
  let(:field) { create_base_field(type: field_type, owner: owner) }

  subject(:skip_rules) { described_class.new(field) }

  describe '#should_skip?' do
    subject(:should_skip?) { skip_rules.should_skip? }

    it { is_expected.to be false }

    context 'when owner is not a Class' do
      let(:owner) { Object.new }

      it { is_expected.to be false }
    end

    context 'with mutation response fields' do
      context 'when owner is a mutation' do
        let(:owner) { Mutations::Issues::Create }

        it { is_expected.to be true }
      end

      context 'when owner is a base mutation' do
        let(:owner) { Mutations::BaseMutation }

        it { is_expected.to be true }
      end
    end

    context 'with permission metadata fields' do
      context 'when owner is a permission type' do
        let(:owner) { Types::PermissionTypes::Project }

        it { is_expected.to be true }
      end

      context 'when owner is a base permission type' do
        let(:owner) { Types::PermissionTypes::BasePermissionType }

        it { is_expected.to be true }
      end

      context 'when return type is a permission type' do
        let(:field_type) { Types::PermissionTypes::Project }

        it { is_expected.to be true }
      end

      context 'when return type is a wrapped permission type' do
        let(:field_type) { [Types::PermissionTypes::Project] }

        it { is_expected.to be true }
      end

      context 'when return type is not a class' do
        before do
          allow(skip_rules).to receive(:unwrap_type).and_return('NotAClass')
        end

        it { is_expected.to be false }
      end
    end
  end
end
