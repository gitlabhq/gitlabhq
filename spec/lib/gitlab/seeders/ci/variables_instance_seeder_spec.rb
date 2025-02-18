# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Seeders::Ci::VariablesInstanceSeeder, feature_category: :ci_variables do
  let(:seeder) { described_class.new }

  let(:custom_seeder) do
    described_class.new(
      seed_count: 2,
      prefix: 'STAGING_'
    )
  end

  describe '#seed' do
    it 'creates instance-level CI variables with default values' do
      expect { seeder.seed }.to change {
        Ci::InstanceVariable.all.count
      }.by(Gitlab::Seeders::Ci::VariablesInstanceSeeder::DEFAULT_SEED_COUNT)

      ci_variable = Ci::InstanceVariable.last

      expect(ci_variable.key.include?('INSTANCE_VAR_')).to eq true
    end

    it 'creates instance-level CI variables with custom arguments' do
      expect { custom_seeder.seed }.to change {
        Ci::InstanceVariable.all.count
      }.by(2)

      ci_variable = Ci::InstanceVariable.last

      expect(ci_variable.key.include?('STAGING_')).to eq true
    end

    it 'skips CI variable creation if CI variable already exists' do
      ::Ci::InstanceVariable.new(
        key: "INSTANCE_VAR_#{::Ci::InstanceVariable.maximum(:id).to_i}",
        value: SecureRandom.hex(32)
      ).save!

      # first id is assigned randomly, so we're creating a new variable
      # based on that id that is sure to be skipped during seed
      ::Ci::InstanceVariable.new(
        key: "INSTANCE_VAR_#{::Ci::InstanceVariable.maximum(:id).to_i + 2}",
        value: SecureRandom.hex(32)
      ).save!

      expect { seeder.seed }.to change {
        Ci::InstanceVariable.all.count
      }.by(Gitlab::Seeders::Ci::VariablesInstanceSeeder::DEFAULT_SEED_COUNT - 1)
    end
  end
end
