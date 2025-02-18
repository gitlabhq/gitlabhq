# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Seeders::Ci::VariablesProjectSeeder, feature_category: :ci_variables do
  let_it_be(:project) { create(:project) }

  let(:seeder) { described_class.new(project_path: project.full_path) }

  let(:custom_seeder) do
    described_class.new(
      project_path: project.full_path,
      seed_count: 2,
      environment_scope: 'staging',
      prefix: 'STAGING_'
    )
  end

  let(:unique_env_seeder) do
    described_class.new(
      project_path: project.full_path,
      seed_count: 2,
      environment_scope: 'unique'
    )
  end

  let(:invalid_project_path_seeder) do
    described_class.new(
      project_path: 'invalid_path',
      seed_count: 1
    )
  end

  describe '#seed' do
    it 'creates project-level CI variables with default values' do
      expect { seeder.seed }.to change {
        project.variables.count
      }.by(Gitlab::Seeders::Ci::VariablesProjectSeeder::DEFAULT_SEED_COUNT)

      ci_variable = project.reload.variables.last

      expect(ci_variable.key.include?('VAR_')).to eq true
      expect(ci_variable.environment_scope).to eq '*'
    end

    it 'creates project-level CI variables with custom arguments' do
      expect { custom_seeder.seed }.to change {
        project.variables.count
      }.by(2)

      ci_variable = project.reload.variables.last

      expect(ci_variable.key.include?('STAGING_')).to eq true
      expect(ci_variable.environment_scope).to eq 'staging'
    end

    it 'creates project-level CI variables with unique environment scopes' do
      unique_env_seeder.seed

      ci_variable_first_env = project.reload.variables.first.environment_scope
      ci_variable_last_env = project.reload.variables.last.environment_scope

      expect(ci_variable_first_env).not_to eq ci_variable_last_env
    end

    it 'skips seeding when project path is invalid' do
      expect { invalid_project_path_seeder.seed }.to change {
        project.variables.count
      }.by(0)
    end

    it 'skips CI variable creation if CI variable already exists' do
      project.variables.create!(
        environment_scope: '*',
        key: "VAR_#{project.variables.maximum(:id).to_i}",
        value: SecureRandom.hex(32)
      )

      # first id is assigned randomly, so we're creating a new variable
      # based on that id that is sure to be skipped during seed
      project.variables.create!(
        environment_scope: '*',
        key: "VAR_#{project.variables.maximum(:id).to_i + 2}",
        value: SecureRandom.hex(32)
      )

      expect { seeder.seed }.to change {
        project.variables.count
      }.by(Gitlab::Seeders::Ci::VariablesProjectSeeder::DEFAULT_SEED_COUNT - 1)
    end
  end
end
