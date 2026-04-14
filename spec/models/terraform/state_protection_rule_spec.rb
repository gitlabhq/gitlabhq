# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::StateProtectionRule, feature_category: :infrastructure_as_code do
  using RSpec::Parameterized::TableSyntax

  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:terraform_state_protection_rules) }
  end

  describe 'enums' do
    it 'defines minimum_access_level_for_write enum' do
      is_expected.to(
        define_enum_for(:minimum_access_level_for_write)
          .with_values(
            developer: Gitlab::Access::DEVELOPER,
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER,
            admin: Gitlab::Access::ADMIN
          )
          .with_prefix(:minimum_access_level_for_write)
      )
    end

    it 'defines allowed_from enum' do
      is_expected.to(
        define_enum_for(:allowed_from)
          .with_values(
            anywhere: 0,
            ci_only: 1,
            ci_on_protected_branch_only: 2
          )
          .with_prefix(:allowed_from)
      )
    end
  end

  describe 'validations' do
    subject(:rule) { build(:terraform_state_protection_rule) }

    describe '#state_name' do
      it { is_expected.to validate_presence_of(:state_name) }
      it { is_expected.to validate_uniqueness_of(:state_name).scoped_to(:project_id) }
      it { is_expected.to validate_length_of(:state_name).is_at_most(255) }
    end

    describe '#minimum_access_level_for_write' do
      it { is_expected.to validate_presence_of(:minimum_access_level_for_write) }
    end

    describe '#allowed_from' do
      it { is_expected.to validate_presence_of(:allowed_from) }
    end
  end
end
