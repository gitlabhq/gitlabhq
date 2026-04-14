# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteAdvisoryPmCheckpoints, feature_category: :software_composition_analysis do
  let(:migration) { described_class.new }
  let(:pm_checkpoints) { table(:pm_checkpoints) }

  let!(:advisory_checkpoint) do
    pm_checkpoints.create!(data_type: 1, purl_type: 1, version_format: 1, sequence: 100, chunk: 1)
  end

  let!(:another_advisory_checkpoint) do
    pm_checkpoints.create!(data_type: 1, purl_type: 2, version_format: 1, sequence: 200, chunk: 2)
  end

  let!(:licenses_checkpoint) do
    pm_checkpoints.create!(data_type: 2, purl_type: 1, version_format: 1, sequence: 300, chunk: 3)
  end

  let!(:cve_enrichment_checkpoint) do
    pm_checkpoints.create!(data_type: 3, purl_type: 1, version_format: 2, sequence: 400, chunk: 4)
  end

  describe '#up' do
    it 'deletes only advisory checkpoints' do
      expect { migration.up }.to change { pm_checkpoints.count }.from(4).to(2)

      expect(pm_checkpoints.where(id: advisory_checkpoint.id)).to be_empty
      expect(pm_checkpoints.where(id: another_advisory_checkpoint.id)).to be_empty
      expect(pm_checkpoints.where(id: licenses_checkpoint.id)).not_to be_empty
      expect(pm_checkpoints.where(id: cve_enrichment_checkpoint.id)).not_to be_empty
    end
  end

  describe '#down' do
    it 'is a no-op' do
      migration.up

      expect { migration.down }.not_to change { pm_checkpoints.count }
    end
  end
end
