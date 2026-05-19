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

  describe '.exists_for_projects_and_state_names' do
    let_it_be(:project1) { create(:project) }
    let_it_be(:project1_rule) { create(:terraform_state_protection_rule, project: project1, state_name: 'production') }

    let_it_be(:project2) { create(:project) }
    let_it_be(:project2_rule) { create(:terraform_state_protection_rule, project: project2, state_name: 'staging') }

    let_it_be(:unprotected_project) { create(:project) }

    let(:single_project_input) do
      [
        [project1.id, 'production'],
        [project1.id, 'unprotected-state']
      ]
    end

    let(:single_project_expected_result) do
      [
        { 'project_id' => project1.id, 'state_name' => 'production', 'protected' => true },
        { 'project_id' => project1.id, 'state_name' => 'unprotected-state', 'protected' => false }
      ]
    end

    let(:multi_projects_input) do
      [
        *single_project_input,
        [project2.id, 'staging'],
        [project2.id, 'unprotected-state']
      ]
    end

    let(:multi_projects_expected_result) do
      [
        *single_project_expected_result,
        { 'project_id' => project2.id, 'state_name' => 'staging', 'protected' => true },
        { 'project_id' => project2.id, 'state_name' => 'unprotected-state', 'protected' => false }
      ]
    end

    let(:unprotected_projects_input) do
      [
        [unprotected_project.id, 'some-state']
      ]
    end

    let(:unprotected_projects_expected_result) do
      [
        { 'project_id' => unprotected_project.id, 'state_name' => 'some-state', 'protected' => false }
      ]
    end

    subject { described_class.exists_for_projects_and_state_names(projects_and_state_names).to_a }

    where(:projects_and_state_names, :expected_result) do
      ref(:single_project_input)       | ref(:single_project_expected_result)
      ref(:multi_projects_input)       | ref(:multi_projects_expected_result)
      ref(:unprotected_projects_input) | ref(:unprotected_projects_expected_result)
      nil                              | []
      []                               | []
    end

    with_them do
      it { is_expected.to match_array expected_result }
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
