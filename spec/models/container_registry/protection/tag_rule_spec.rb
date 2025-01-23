# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::TagRule, type: :model, feature_category: :container_registry do
  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:container_registry_protection_tag_rules) }
  end

  describe 'enums' do
    it 'defines an enum for minimum access level for push' do
      is_expected.to(
        define_enum_for(:minimum_access_level_for_push)
          .with_values(
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_push)
      )
    end

    it 'defines an enum for minimum access level for delete' do
      is_expected.to(
        define_enum_for(:minimum_access_level_for_delete)
          .with_values(
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_delete)
      )
    end
  end

  describe 'validations' do
    subject { build(:container_registry_protection_tag_rule) }

    describe '#tag_name_pattern' do
      it { is_expected.to validate_presence_of(:tag_name_pattern) }
      it { is_expected.to validate_length_of(:tag_name_pattern).is_at_most(100) }
      it { is_expected.to validate_uniqueness_of(:tag_name_pattern).scoped_to(:project_id) }

      describe 'regex validations' do
        valid_regexps = %w[master .* v.+ v10.1.* (?:v.+|master|release)]
        invalid_regexps = ['[', '(?:v.+|master|release']

        valid_regexps.each do |valid_regexp|
          it { is_expected.to allow_value(valid_regexp).for(:tag_name_pattern) }
        end

        invalid_regexps.each do |invalid_regexp|
          it { is_expected.not_to allow_value(invalid_regexp).for(:tag_name_pattern) }
        end
      end
    end

    describe '#validate_access_levels' do
      subject(:tag_rule) { described_class.new(attributes) }

      let(:minimum_access_level_for_delete) { Gitlab::Access::ADMIN }
      let(:minimum_access_level_for_push) { Gitlab::Access::OWNER }
      let(:attributes) do
        {
          tag_name_pattern: '.*',
          minimum_access_level_for_delete: minimum_access_level_for_delete,
          minimum_access_level_for_push: minimum_access_level_for_push
        }
      end

      context 'when both access levels are present' do
        it 'is valid' do
          expect(tag_rule).to be_valid
        end
      end

      context 'when both access levels are nil' do
        let(:minimum_access_level_for_delete) { nil }
        let(:minimum_access_level_for_push) { nil }

        it 'is valid' do
          expect(tag_rule).to be_valid
        end
      end

      context 'when minimum_access_level_for_push is nil' do
        let(:minimum_access_level_for_push) { nil }

        it 'is not valid' do
          expect(tag_rule).not_to be_valid
          expect(tag_rule.errors[:base]).to include('Access levels should either both be present or both be nil')
        end
      end

      context 'when minimum_access_level_for_delete is nil' do
        let(:minimum_access_level_for_delete) { nil }

        it 'is not valid' do
          expect(tag_rule).not_to be_valid
          expect(tag_rule.errors[:base]).to include('Access levels should either both be present or both be nil')
        end
      end
    end
  end

  describe '.for_actions_and_access' do
    let(:rule_one) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'one',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :maintainer)
    end

    let(:rule_two) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'two',
        minimum_access_level_for_push: :owner,
        minimum_access_level_for_delete: :maintainer)
    end

    let(:rule_three) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'three',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :admin)
    end

    let(:rule_four) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'four',
        minimum_access_level_for_push: :admin,
        minimum_access_level_for_delete: :admin)
    end

    before do
      rule_one
      rule_two
      rule_three
      rule_four
    end

    using RSpec::Parameterized::TableSyntax

    where(:user_access_level, :actions, :expected_rules) do
      Gitlab::Access::DEVELOPER  | ['push']         | lazy { [rule_one, rule_two, rule_three, rule_four] }
      Gitlab::Access::DEVELOPER  | ['delete']       | lazy { [rule_one, rule_two, rule_three, rule_four] }
      Gitlab::Access::DEVELOPER  | %w[push delete]  | lazy { [rule_one, rule_two, rule_three, rule_four] }
      Gitlab::Access::DEVELOPER  | ['unknown']      | lazy { [rule_one, rule_two, rule_three, rule_four] }
      Gitlab::Access::DEVELOPER  | %w[push unknown] | lazy { [rule_one, rule_two, rule_three, rule_four] }
      Gitlab::Access::MAINTAINER | ['push']         | lazy { [rule_two, rule_four] }
      Gitlab::Access::MAINTAINER | ['delete']       | lazy { [rule_three, rule_four] }
      Gitlab::Access::MAINTAINER | %w[push delete]  | lazy { [rule_two, rule_three, rule_four] }
      Gitlab::Access::OWNER      | ['push']         | lazy { [rule_four] }
      Gitlab::Access::OWNER      | ['delete']       | lazy { [rule_three, rule_four] }
      Gitlab::Access::OWNER      | %w[push delete]  | lazy { [rule_three, rule_four] }
      Gitlab::Access::ADMIN      | ['push']         | lazy { [] }
      Gitlab::Access::ADMIN      | ['delete']       | lazy { [] }
      Gitlab::Access::ADMIN      | %w[push delete]  | lazy { [] }
    end

    with_them do
      subject { described_class.for_actions_and_access(actions, user_access_level) }

      it 'returns the expected rules' do
        is_expected.to match_array(expected_rules)
      end
    end
  end

  describe '#push_restricted?' do
    let(:rule) do
      create(
        :container_registry_protection_tag_rule,
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :owner
      )
    end

    it 'returns true if user access level is below the push minimum' do
      expect(rule.push_restricted?(Gitlab::Access::DEVELOPER)).to be(true)
    end

    it 'returns false if user access level meets the push minimum' do
      expect(rule.push_restricted?(Gitlab::Access::MAINTAINER)).to be(false)
    end

    it 'returns false if user access level exceeds the push minimum' do
      expect(rule.push_restricted?(Gitlab::Access::OWNER)).to be(false)
    end
  end

  describe '#delete_restricted?' do
    let(:rule) do
      create(
        :container_registry_protection_tag_rule,
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :owner
      )
    end

    it 'returns true if user access level is below the delete minimum' do
      expect(rule.delete_restricted?(Gitlab::Access::MAINTAINER)).to be(true)
    end

    it 'returns false if user access level meets the delete minimum' do
      expect(rule.delete_restricted?(Gitlab::Access::OWNER)).to be(false)
    end

    it 'returns false if user access level exceeds the delete minimum' do
      expect(rule.delete_restricted?(Gitlab::Access::ADMIN)).to be(false)
    end
  end
end
