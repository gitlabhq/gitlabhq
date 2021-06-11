# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe MigrateElasticIndexSettings do
  let(:elastic_index_settings) { table(:elastic_index_settings) }
  let(:application_settings) { table(:application_settings) }

  context 'with application_settings present' do
    before do
      application_settings.create!(elasticsearch_replicas: 2, elasticsearch_shards: 15)
    end

    it 'migrates settings' do
      migrate!

      settings = elastic_index_settings.all

      expect(settings.size).to eq 1

      setting = settings.first

      expect(setting.number_of_replicas).to eq(2)
      expect(setting.number_of_shards).to eq(15)
    end
  end

  context 'without application_settings present' do
    it 'migrates settings' do
      migrate!

      settings = elastic_index_settings.all

      expect(settings.size).to eq 1

      setting = elastic_index_settings.first

      expect(setting.number_of_replicas).to eq(1)
      expect(setting.number_of_shards).to eq(5)
    end
  end
end
