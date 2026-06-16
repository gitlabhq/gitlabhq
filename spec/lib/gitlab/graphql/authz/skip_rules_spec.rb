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

    context 'with edge wrapper fields' do
      context 'when owner is an edge type' do
        let(:owner) { Types::BaseEdge }

        it { is_expected.to be true }
      end

      context 'when owner is a base edge type' do
        let(:owner) { GraphQL::Types::Relay::BaseEdge }

        it { is_expected.to be true }
      end
    end

    context 'when the field traverses from an authorized type to another authorized type' do
      # GroupMemberType has a `user` field returning UserType which has a directive,
      # so GroupMemberType has deeper authorized fields -> skip fires.
      let(:owner) { Types::GroupType }
      let(:field_type) { Types::GroupMemberType.connection_type }

      it 'skips authorization when the return type has deeper authorized sub-fields' do
        is_expected.to be true
      end

      context 'when the field has its own granular_token directive' do
        let(:directive) { create_directive(boundary: 'itself', permissions: ['read_group']) }
        let(:field) { create_field_with_directive(directive: directive, type: field_type, owner: owner) }

        it 'does not skip — an explicit field-level directive always wins' do
          is_expected.to be false
        end
      end

      context 'when the owner type has no granular_token directive' do
        let(:owner) do
          Class.new(GraphQL::Schema::Object) { graphql_name 'OwnerWithoutGranularToken' }
        end

        it 'does not skip — there is no parent tax to drop' do
          is_expected.to be false
        end
      end

      context 'when the return type has no granular_token directive' do
        let(:field_type) { GraphQL::Types::String }

        it 'does not skip — owner-level directive is the authoritative gate' do
          is_expected.to be false
        end
      end

      context 'when the return type is a list of authorized objects' do
        let(:field_type) { [Types::GroupMemberType] }

        it 'unwraps the list and still skips' do
          is_expected.to be true
        end
      end

      context 'when the return type has no deeper authorized sub-fields (leaf type)' do
        # LabelType fields (id, archived, lock_on_merge, description_html) all return
        # scalars with no directives, so it is a leaf. Skipping would leave an empty
        # collection unchecked, so the skip must not fire.
        let(:owner) { Types::GroupType }
        let(:field_type) { Types::LabelType.connection_type }

        it 'does not skip — leaf return types must be checked at the collection level' do
          is_expected.to be false
        end
      end
    end
  end
end
