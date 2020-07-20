# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:generic_payload) do
    {
      'title' => 'Alert title',
      'start_time' => '2020-04-27T10:10:22.265949279Z',
      'custom' => { 'param' => 73 }
    }
  end
  let_it_be(:alert) do
    create(:alert_management_alert, :with_description, :with_host, :with_service, :with_monitoring_tool, project: project, payload: generic_payload)
  end

  subject(:presenter) { described_class.new(alert) }

  describe '#issue_description' do
    let(:markdown_line_break) { '  ' }

    it 'returns an alert issue description' do
      expect(presenter.issue_description).to eq(
        <<~MARKDOWN.chomp
          #### Summary

          **Start time:** #{presenter.start_time}#{markdown_line_break}
          **Severity:** #{presenter.severity}#{markdown_line_break}
          **Service:** #{alert.service}#{markdown_line_break}
          **Monitoring tool:** #{alert.monitoring_tool}#{markdown_line_break}
          **Hosts:** #{alert.hosts.join(' ')}#{markdown_line_break}
          **Description:** #{alert.description}

          #### Alert Details

          **custom.param:** 73
        MARKDOWN
      )
    end
  end

  describe '#metrics_dashboard_url' do
    it 'is not defined' do
      expect(presenter.metrics_dashboard_url).to be_nil
    end
  end
end
