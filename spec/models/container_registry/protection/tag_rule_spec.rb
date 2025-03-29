# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::TagRule, type: :model, feature_category: :container_registry do
  using RSpec::Parameterized::TableSyntax

  shared_examples 'returning same result for different access levels' do |expected_result|
    where(:user_access_level) do
      [
        Gitlab::Access::MAINTAINER,
        Gitlab::Access::OWNER,
        Gitlab::Access::ADMIN
      ]
    end

    with_them do
      it { is_expected.to be(expected_result) }
    end
  end

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
    let_it_be(:rule_one) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'one',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :maintainer)
    end

    let_it_be(:rule_two) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'two',
        minimum_access_level_for_push: :owner,
        minimum_access_level_for_delete: :maintainer)
    end

    let_it_be(:rule_three) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'three',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :admin)
    end

    let_it_be(:rule_four) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'four',
        minimum_access_level_for_push: :admin,
        minimum_access_level_for_delete: :admin)
    end

    let_it_be(:rule_five) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'five',
        minimum_access_level_for_push: nil,
        minimum_access_level_for_delete: nil)
    end

    where(:user_access_level, :actions, :expected_rules) do
      Gitlab::Access::DEVELOPER  | ['push']         | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::DEVELOPER  | ['delete']       | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::DEVELOPER  | %w[push delete]  | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::DEVELOPER  | ['unknown']      | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::DEVELOPER  | %w[push unknown] | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::MAINTAINER | ['push']         | lazy { [rule_two, rule_four, rule_five] }
      Gitlab::Access::MAINTAINER | ['delete']       | lazy { [rule_three, rule_four, rule_five] }
      Gitlab::Access::MAINTAINER | %w[push delete]  | lazy { [rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::OWNER      | ['push']         | lazy { [rule_four, rule_five] }
      Gitlab::Access::OWNER      | ['delete']       | lazy { [rule_three, rule_four, rule_five] }
      Gitlab::Access::OWNER      | %w[push delete]  | lazy { [rule_three, rule_four, rule_five] }
      Gitlab::Access::ADMIN      | ['push']         | lazy { [rule_five] }
      Gitlab::Access::ADMIN      | ['delete']       | lazy { [rule_five] }
      Gitlab::Access::ADMIN      | %w[push delete]  | lazy { [rule_five] }
    end

    with_them do
      subject { described_class.for_actions_and_access(actions, user_access_level) }

      it 'returns the expected rules' do
        is_expected.to match_array(expected_rules)
      end
    end
  end

  describe '.for_delete_and_access' do
    let_it_be(:rule_one) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'one',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :maintainer)
    end

    let_it_be(:rule_two) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'two',
        minimum_access_level_for_push: :owner,
        minimum_access_level_for_delete: :maintainer)
    end

    let_it_be(:rule_three) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'three',
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :admin)
    end

    let_it_be(:rule_four) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'four',
        minimum_access_level_for_push: :admin,
        minimum_access_level_for_delete: :admin)
    end

    let_it_be(:rule_five) do
      create(:container_registry_protection_tag_rule,
        tag_name_pattern: 'five',
        minimum_access_level_for_push: nil,
        minimum_access_level_for_delete: nil)
    end

    where(:user_access_level, :expected_rules) do
      Gitlab::Access::DEVELOPER  | lazy { [rule_one, rule_two, rule_three, rule_four, rule_five] }
      Gitlab::Access::MAINTAINER | lazy { [rule_three, rule_four, rule_five] }
      Gitlab::Access::OWNER      | lazy { [rule_three, rule_four, rule_five] }
      Gitlab::Access::ADMIN      | lazy { [rule_five] }
    end

    with_them do
      subject { described_class.for_delete_and_access(user_access_level) }

      it 'returns the expected rules' do
        is_expected.to match_array(expected_rules)
      end
    end
  end

  describe '.tag_name_patterns_for_projects' do
    let_it_be(:rule) { create(:container_registry_protection_tag_rule) }
    let_it_be(:rule2) { create(:container_registry_protection_tag_rule) }

    subject(:result) { described_class.tag_name_patterns_for_project(rule.project_id) }

    it 'contains matched rule' do
      expect(result.pluck(:tag_name_pattern)).to contain_exactly(rule.tag_name_pattern)
    end

    it 'selects only the tag_name_pattern' do
      expect(result.select_values).to contain_exactly(:tag_name_pattern)
    end
  end

  describe '#push_restricted?' do
    let_it_be(:rule) do
      build(
        :container_registry_protection_tag_rule,
        minimum_access_level_for_push: :owner,
        minimum_access_level_for_delete: :maintainer
      )
    end

    subject { rule.push_restricted?(user_access_level) }

    where(:user_access_level, :expected_result) do
      Gitlab::Access::MAINTAINER  | true
      Gitlab::Access::OWNER       | false
      Gitlab::Access::ADMIN       | false
    end

    with_them do
      it { is_expected.to be(expected_result) }
    end

    context 'for an immutable tag rule' do
      let_it_be(:rule) do
        build(:container_registry_protection_tag_rule, :immutable)
      end

      it_behaves_like 'returning same result for different access levels', true

      context 'when the feature container_registry_immutable_tags is disabled' do
        before do
          stub_feature_flags(container_registry_immutable_tags: false)
        end

        it_behaves_like 'returning same result for different access levels', false
      end
    end
  end

  describe '#delete_restricted?' do
    let_it_be(:rule) do
      build(
        :container_registry_protection_tag_rule,
        minimum_access_level_for_push: :maintainer,
        minimum_access_level_for_delete: :owner
      )
    end

    subject { rule.delete_restricted?(user_access_level) }

    where(:user_access_level, :expected_result) do
      Gitlab::Access::MAINTAINER  | true
      Gitlab::Access::OWNER       | false
      Gitlab::Access::ADMIN       | false
    end

    with_them do
      it { is_expected.to be(expected_result) }
    end

    context 'for an immutable tag rule' do
      let_it_be(:rule) do
        build(:container_registry_protection_tag_rule, :immutable)
      end

      it_behaves_like 'returning same result for different access levels', true

      context 'when the feature container_registry_immutable_tags is disabled' do
        before do
          stub_feature_flags(container_registry_immutable_tags: false)
        end

        it_behaves_like 'returning same result for different access levels', false
      end
    end
  end

  describe '#immutable?' do
    subject { rule.immutable? }

    context 'when access levels are nil' do
      let(:rule) do
        build(
          :container_registry_protection_tag_rule,
          minimum_access_level_for_push: nil,
          minimum_access_level_for_delete: nil
        )
      end

      it { is_expected.to be(true) }
    end

    context 'when access levels are not nil' do
      let(:rule) do
        build(
          :container_registry_protection_tag_rule,
          minimum_access_level_for_push: :owner,
          minimum_access_level_for_delete: :owner
        )
      end

      it { is_expected.to be(false) }
    end
  end
end
