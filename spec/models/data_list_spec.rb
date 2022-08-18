# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DataList do
  describe '#to_array' do
    let(:jira_integration) { create(:jira_integration) }
    let(:zentao_integration) { create(:zentao_integration) }
    let(:cases) do
      [
        [jira_integration, 'Integrations::JiraTrackerData', 'integration_id'],
        [zentao_integration, 'Integrations::ZentaoTrackerData', 'integration_id']
      ]
    end

    def data_list(integration)
      DataList.new([integration], integration.to_database_hash, integration.data_fields.class).to_array
    end

    it 'returns current data' do
      cases.each do |integration, data_fields_class_name, foreign_key|
        data_fields_klass, columns, values_items = data_list(integration)

        expect(data_fields_klass.to_s).to eq data_fields_class_name
        expect(columns.last).to eq foreign_key
        values = values_items.first
        expect(values.last).to eq integration.id
      end
    end
  end
end
