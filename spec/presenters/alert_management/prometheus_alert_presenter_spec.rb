# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::PrometheusAlertPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:prometheus_payload) do
    {
      'annotations' => {
        'title' => 'Alert title',
        'gitlab_incident_markdown' => '**`markdown example`**',
        'custom annotation' => 'custom annotation value'
      },
      'startsAt' => '2020-04-27T10:10:22.265949279Z',
      'generatorURL' => 'http://8d467bd4607a:9090/graph?g0.expr=vector%281%29&g0.tab=1'
    }
  end
  let_it_be(:alert) do
    create(:alert_management_alert, :prometheus, project: project, payload: prometheus_payload)
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
          **full_query:** `vector(1)`#{markdown_line_break}
          **Monitoring tool:** Prometheus

          #### Alert Details

          **custom annotation:** custom annotation value

          ---

          **`markdown example`**
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
