# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Seeders::Ci::VariablesGroupSeeder, feature_category: :ci_variables do
  let_it_be(:group) { create(:group) }

  let(:seeder) { described_class.new(name: group.name) }

  let(:custom_seeder) do
    described_class.new(
      name: group.name,
      seed_count: 2,
      environment_scope: 'staging',
      prefix: 'STAGING_'
    )
  end

  let(:unique_env_seeder) do
    described_class.new(
      name: group.name,
      seed_count: 2,
      environment_scope: 'unique'
    )
  end

  let(:invalid_group_name_seeder) do
    described_class.new(
      name: 'nonexistent_group',
      seed_count: 1
    )
  end

  describe '#seed' do
    it 'creates group-level CI variables with default values' do
      expect { seeder.seed }.to change {
        group.variables.count
      }.by(Gitlab::Seeders::Ci::VariablesGroupSeeder::DEFAULT_SEED_COUNT)

      ci_variable = group.reload.variables.last

      expect(ci_variable.key.include?('GROUP_VAR_')).to eq true
      expect(ci_variable.environment_scope).to eq '*'
    end

    it 'creates group-level CI variables with custom arguments' do
      expect { custom_seeder.seed }.to change {
        group.variables.count
      }.by(2)

      ci_variable = group.reload.variables.last

      expect(ci_variable.key.include?('STAGING_')).to eq true
      expect(ci_variable.environment_scope).to eq 'staging'
    end

    it 'creates group-level CI variables with unique environment scopes' do
      unique_env_seeder.seed

      ci_variable_first_env = group.reload.variables.first.environment_scope
      ci_variable_last_env = group.reload.variables.last.environment_scope

      expect(ci_variable_first_env).not_to eq ci_variable_last_env
    end

    it 'skips seeding when group name is invalid' do
      expect { invalid_group_name_seeder.seed }.to change {
        group.variables.count
      }.by(0)
    end

    it 'skips CI variable creation if CI variable already exists' do
      group.variables.create!(
        environment_scope: '*',
        key: "GROUP_VAR_#{group.variables.maximum(:id).to_i}",
        value: SecureRandom.hex(32)
      )

      # first id is assigned randomly, so we're creating a new variable
      # based on that id that is sure to be skipped during seed
      group.variables.create!(
        environment_scope: '*',
        key: "GROUP_VAR_#{group.variables.maximum(:id).to_i + 2}",
        value: SecureRandom.hex(32)
      )

      expect { seeder.seed }.to change {
        group.variables.count
      }.by(Gitlab::Seeders::Ci::VariablesGroupSeeder::DEFAULT_SEED_COUNT - 1)
    end
  end
end
