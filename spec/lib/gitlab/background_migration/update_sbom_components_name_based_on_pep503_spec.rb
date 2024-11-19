# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateSbomComponentsNameBasedOnPep503, schema: 20240828162042, feature_category: :software_composition_analysis do
  before(:all) do
    # This migration will not work if a sec database is configured. It should be finalized and removed prior to
    # sec db rollout.
    # Consult https://gitlab.com/gitlab-org/gitlab/-/merge_requests/171707 for more info.
    skip_if_multiple_databases_are_setup(:sec)
  end

  let(:components) { table(:sbom_components) }

  before do
    %w[aws-cdk.region-info azure.identity backports.cached-property backports.csv].each do |input_name|
      components.create!(name: input_name, purl_type: 8, component_type: 0)
    end
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        start_id: components.first.id,
        end_id: components.last.id,
        batch_table: :sbom_components,
        batch_column: :id,
        sub_batch_size: components.count,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    let(:expected_names) { %w[aws-cdk-region-info azure-identity backports-cached-property backports-csv] }

    it 'successfully updates name according to PEP 0503' do
      expect(Gitlab::BackgroundMigration::Logger).not_to receive(:warn)

      perform_migration

      expect(components.pluck(:name)).to eq(expected_names)
    end

    context 'with existing record in regards to name, purl_type and component_type' do
      before do
        components.create!(name: 'aws-cdk-region-info', purl_type: 8, component_type: 0)
      end

      it 'raises ActiveRecord::RecordNotUnique' do
        expect(Gitlab::BackgroundMigration::Logger).to receive(:warn)

        perform_migration
      end
    end
  end
end
