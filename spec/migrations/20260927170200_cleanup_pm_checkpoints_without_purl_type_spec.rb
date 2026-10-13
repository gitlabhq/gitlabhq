# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupPmCheckpointsWithoutPurlType, feature_category: :software_composition_analysis do
  let(:migration) { described_class.new }
  let(:checkpoints) { table(:pm_checkpoints) }

  # Only CVE enrichment (data_type 3) is synced without a purl_type.
  let!(:cve_enrichment_checkpoint) do
    checkpoints.create!(data_type: 3, version_format: 2, purl_type: nil, sequence: 0, chunk: 1,
      full_sync_target_sequence: 0)
  end

  let!(:advisory_checkpoint) do
    checkpoints.create!(data_type: 1, version_format: 2, purl_type: 6, sequence: 1790000000, chunk: 2)
  end

  let!(:license_checkpoint) do
    checkpoints.create!(data_type: 2, version_format: 3, purl_type: 8, sequence: 1790000001, chunk: 3)
  end

  let!(:malware_advisory_checkpoint) do
    checkpoints.create!(data_type: 4, version_format: 3, purl_type: 6, sequence: 1790000002, chunk: 4)
  end

  describe '#up' do
    it 'does not change any checkpoint' do
      expect { migration.up }.not_to change { checkpoints.order(:id).map(&:attributes) }
    end
  end

  describe '#down' do
    it 'deletes only the checkpoints without a purl_type', :aggregate_failures do
      migration.up

      expect { migration.down }.to change { checkpoints.count }.from(4).to(3)

      expect(checkpoints.find_by(id: cve_enrichment_checkpoint.id)).to be_nil
      expect(checkpoints.where(purl_type: nil)).to be_empty
      expect(checkpoints.find(advisory_checkpoint.id)).to have_attributes(sequence: 1790000000, chunk: 2)
      expect(checkpoints.find(license_checkpoint.id)).to have_attributes(sequence: 1790000001, chunk: 3)
      expect(checkpoints.find(malware_advisory_checkpoint.id)).to have_attributes(sequence: 1790000002, chunk: 4)
    end
  end
end
