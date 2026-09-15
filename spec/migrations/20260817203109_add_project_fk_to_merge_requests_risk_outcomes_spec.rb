# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddProjectFkToMergeRequestsRiskOutcomes, migration: :gitlab_main_org,
  feature_category: :duo_code_review do
  let(:connection) { described_class.new.connection }
  let(:table_name) { :merge_requests_risk_outcomes }

  describe '#up', :aggregate_failures do
    it 'adds the foreign key on project_id' do
      expect { migrate! }.to change {
        connection.foreign_keys(table_name).any? { |fk| fk.column == 'project_id' }
      }.from(false).to(true)
    end
  end

  describe '#down', :aggregate_failures do
    it 'removes the foreign key on project_id' do
      migrate!
      schema_migrate_down!

      expect(connection.foreign_keys(table_name).find { |fk| fk.column == 'project_id' }).to be_nil
    end
  end
end
