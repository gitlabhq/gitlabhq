# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Protection::Rule, type: :model, feature_category: :container_registry do
  it_behaves_like 'having unique enum values'

  describe 'relationships' do
    it { is_expected.to belong_to(:project).inverse_of(:container_registry_protection_rules) }
  end

  describe 'enums' do
    it {
      is_expected.to(
        define_enum_for(:push_protected_up_to_access_level)
          .with_values(
            developer: Gitlab::Access::DEVELOPER,
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER
          )
          .with_prefix(:push_protected_up_to)
      )
    }

    it {
      is_expected.to(
        define_enum_for(:delete_protected_up_to_access_level)
          .with_values(
            developer: Gitlab::Access::DEVELOPER,
            maintainer: Gitlab::Access::MAINTAINER,
            owner: Gitlab::Access::OWNER
          )
          .with_prefix(:delete_protected_up_to)
      )
    }
  end

  describe 'validations' do
    subject { build(:container_registry_protection_rule) }

    describe '#repository_path_pattern' do
      it { is_expected.to validate_presence_of(:repository_path_pattern) }
      it { is_expected.to validate_length_of(:repository_path_pattern).is_at_most(255) }
    end

    describe '#delete_protected_up_to_access_level' do
      it { is_expected.to validate_presence_of(:delete_protected_up_to_access_level) }
    end

    describe '#push_protected_up_to_access_level' do
      it { is_expected.to validate_presence_of(:push_protected_up_to_access_level) }
    end
  end
end
