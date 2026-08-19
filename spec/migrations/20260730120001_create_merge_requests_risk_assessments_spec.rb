# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateMergeRequestsRiskAssessments, migration: :gitlab_main_org, feature_category: :duo_code_review do
  let(:merge_requests_risk_assessments) { table(:merge_requests_risk_assessments) }

  before do
    migrate!
  end

  describe '#up' do
    it 'creates the merge_requests_risk_assessments table' do
      expect(merge_requests_risk_assessments.table_exists?).to be true
    end

    it 'sets the correct column types and defaults', :aggregate_failures do
      status_column = merge_requests_risk_assessments.columns.find { |c| c.name == 'status' }
      diff_sha_column = merge_requests_risk_assessments.columns.find { |c| c.name == 'diff_sha' }
      domain_tags_column = merge_requests_risk_assessments.columns.find { |c| c.name == 'domain_tags' }
      signal_breakdown_column = merge_requests_risk_assessments.columns.find { |c| c.name == 'signal_breakdown' }
      classification_column = merge_requests_risk_assessments.columns.find { |c| c.name == 'classification' }

      expect(status_column.null).to be false
      expect(status_column.default).to eq('0')

      expect(diff_sha_column.null).to be false

      expect(domain_tags_column.array).to be true
      expect(domain_tags_column.null).to be false
      expect(domain_tags_column.default).to eq('{}')

      expect(signal_breakdown_column.null).to be false
      expect(signal_breakdown_column.default).to eq('[]')

      expect(classification_column.null).to be false
      expect(classification_column.default).to eq('{}')
    end

    it 'creates the unique index on merge_request_id', :aggregate_failures do
      indexes = ActiveRecord::Base.connection.indexes(:merge_requests_risk_assessments)
      merge_request_index = indexes.find { |i| i.columns == ['merge_request_id'] }

      expect(merge_request_index).to be_present
      expect(merge_request_index.unique).to be true
      expect(merge_request_index.name).to eq('index_merge_requests_risk_assessments_on_merge_request_id')
    end

    it 'creates a non-unique index on project_id', :aggregate_failures do
      indexes = ActiveRecord::Base.connection.indexes(:merge_requests_risk_assessments)
      project_index = indexes.find { |i| i.columns == ['project_id'] }

      expect(project_index).to be_present
      expect(project_index.unique).to be false
      expect(project_index.name).to eq('index_merge_requests_risk_assessments_on_project_id')
    end

    it 'creates the foreign key constraint on merge_request_id', :aggregate_failures do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:merge_requests_risk_assessments)
      merge_request_fk = foreign_keys.find { |fk| fk.column == 'merge_request_id' }

      expect(merge_request_fk).to be_present
      expect(merge_request_fk.to_table).to eq('merge_requests')
      expect(merge_request_fk.on_delete).to eq(:cascade)
    end

    it 'does not create a foreign key on project_id' do
      foreign_keys = ActiveRecord::Base.connection.foreign_keys(:merge_requests_risk_assessments)

      expect(foreign_keys.find { |fk| fk.column == 'project_id' }).to be_nil
    end
  end

  describe '#down' do
    it 'drops the merge_requests_risk_assessments table' do
      schema_migrate_down!

      expect(merge_requests_risk_assessments.table_exists?).to be false
    end
  end
end
