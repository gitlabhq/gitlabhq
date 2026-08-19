# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateMergeRequestsRiskOutcomes, migration: :gitlab_main_org, feature_category: :duo_code_review do
  let(:merge_requests_risk_outcomes) { table(:merge_requests_risk_outcomes) }

  before do
    migrate!
  end

  describe '#up' do
    it 'creates the merge_requests_risk_outcomes table' do
      expect(merge_requests_risk_outcomes.table_exists?).to be true
    end

    it 'sets the correct column types and defaults', :aggregate_failures do
      observed_at_column = merge_requests_risk_outcomes.columns.find { |c| c.name == 'observed_at' }
      signal_type_column = merge_requests_risk_outcomes.columns.find { |c| c.name == 'signal_type' }
      confidence_column = merge_requests_risk_outcomes.columns.find { |c| c.name == 'confidence' }
      evidence_column = merge_requests_risk_outcomes.columns.find { |c| c.name == 'evidence' }

      expect(observed_at_column.null).to be false
      expect(signal_type_column.null).to be false
      expect(confidence_column.null).to be false

      expect(evidence_column.null).to be false
      expect(evidence_column.default).to eq('{}')
    end

    it 'creates the unique index on risk_assessment_id and signal_type', :aggregate_failures do
      indexes = ActiveRecord::Base.connection.indexes(:merge_requests_risk_outcomes)
      assessment_signal_index = indexes.find { |i| i.columns == %w[risk_assessment_id signal_type] }

      expect(assessment_signal_index).to be_present
      expect(assessment_signal_index.unique).to be true
      expect(assessment_signal_index.name).to eq('idx_mr_risk_outcomes_on_assessment_and_signal')
    end

    it 'creates a non-unique index on project_id', :aggregate_failures do
      indexes = ActiveRecord::Base.connection.indexes(:merge_requests_risk_outcomes)
      project_index = indexes.find { |i| i.columns == ['project_id'] }

      expect(project_index).to be_present
      expect(project_index.unique).to be false
      expect(project_index.name).to eq('index_merge_requests_risk_outcomes_on_project_id')
    end

    it 'creates the foreign key constraint on risk_assessment_id', :aggregate_failures do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:merge_requests_risk_outcomes)
      assessment_fk = foreign_keys.find { |fk| fk.column == 'risk_assessment_id' }

      expect(assessment_fk).to be_present
      expect(assessment_fk.to_table).to eq('merge_requests_risk_assessments')
      expect(assessment_fk.on_delete).to eq(:cascade)
    end

    it 'does not create a foreign key on project_id' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:merge_requests_risk_outcomes)

      expect(foreign_keys.find { |fk| fk.column == 'project_id' }).to be_nil
    end
  end

  describe '#down' do
    it 'drops the merge_requests_risk_outcomes table' do
      schema_migrate_down!

      expect(merge_requests_risk_outcomes.table_exists?).to be false
    end
  end
end
