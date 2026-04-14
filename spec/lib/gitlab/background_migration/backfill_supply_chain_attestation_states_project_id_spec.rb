# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSupplyChainAttestationStatesProjectId,
  feature_category: :geo_replication do
  include_examples 'desired sharding key backfill job' do
    let(:batch_table) { :supply_chain_attestation_states }
    let(:backfill_column) { :project_id }
    let(:batch_column) { :id }
    let(:backfill_via_table) { :slsa_attestations }
    let(:backfill_via_column) { :project_id }
    let(:backfill_via_foreign_key) { :supply_chain_attestation_id }
  end
end
