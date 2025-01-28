# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Seeders::ProjectEnvironmentSeeder, feature_category: :ci_variables do
  let_it_be(:project) { create(:project) }

  let(:seeder) { described_class.new(project_path: project.full_path) }
  let(:custom_seeder) do
    described_class.new(project_path: project.full_path, seed_count: 2, prefix: 'staging_')
  end

  let(:invalid_project_path_seeder) do
    described_class.new(project_path: 'invalid_path', seed_count: 1)
  end

  describe '#seed' do
    it 'creates environments for the project' do
      expect { seeder.seed }.to change {
        project.environments.count
      }.by(Gitlab::Seeders::ProjectEnvironmentSeeder::DEFAULT_SEED_COUNT)
    end

    it 'creates environments with custom arguments' do
      expect { custom_seeder.seed }.to change {
        project.environments.count
      }.by(2)

      env = project.environments.last

      expect(env.name.include?('staging_')).to eq true
    end

    it 'skips seeding when project path is invalid' do
      expect { invalid_project_path_seeder.seed }.to change {
        project.environments.count
      }.by(0)
    end

    it 'skips environment creation if environment already exists' do
      project.environments.create!(name: "ENV_#{project.environments.maximum(:id).to_i}")

      # first id is assigned randomly, so we're creating a new variable
      # based on that id that is sure to be skipped during seed
      project.environments.create!(name: "ENV_#{project.environments.maximum(:id).to_i + 2}")

      expect { seeder.seed }.to change {
        project.environments.count
      }.by(Gitlab::Seeders::ProjectEnvironmentSeeder::DEFAULT_SEED_COUNT - 1)
    end
  end
end
