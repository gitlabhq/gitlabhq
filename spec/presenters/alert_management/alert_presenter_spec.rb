# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::AlertPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:payload) do
    {
      'title' => 'Alert title',
      'start_time' => '2020-04-27T10:10:22.265949279Z',
      'custom' => {
        'alert' => {
          'fields' => %w[one two]
        }
      },
      'yet' => {
        'another' => 73
      }
    }
  end

  let_it_be(:alert) { create(:alert_management_alert, project: project, payload: payload) }

  let(:alert_url) { "http://localhost/#{project.full_path}/-/alert_management/#{alert.iid}/details" }

  subject(:presenter) { described_class.new(alert) }

  describe '#issue_description' do
    let_it_be(:alert) { create(:alert_management_alert, project: project, payload: {}) }

    let(:markdown_line_break) { '  ' }

    subject { presenter.issue_description }

    context 'with an empty payload' do
      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **Severity:** #{presenter.severity}#{markdown_line_break}
            **GitLab alert:** #{alert_url}

          MARKDOWN
        )
      end
    end

    context 'with optional alert attributes' do
      let_it_be(:alert) do
        create(:alert_management_alert, :with_description, :with_host, :with_service, :with_monitoring_tool, project: project, payload: payload)
      end

      before do
        allow(alert.parsed_payload).to receive(:full_query).and_return('metric > 1')
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **Severity:** #{presenter.severity}#{markdown_line_break}
            **full_query:** `metric > 1`#{markdown_line_break}
            **Service:** #{alert.service}#{markdown_line_break}
            **Monitoring tool:** #{alert.monitoring_tool}#{markdown_line_break}
            **Hosts:** #{alert.hosts.join(' ')}#{markdown_line_break}
            **Description:** #{alert.description}#{markdown_line_break}
            **GitLab alert:** #{alert_url}

          MARKDOWN
        )
      end
    end

    context 'with incident markdown' do
      before do
        allow(alert.parsed_payload).to receive(:alert_markdown).and_return('**`markdown example`**')
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **Severity:** #{presenter.severity}#{markdown_line_break}
            **GitLab alert:** #{alert_url}


            ---

            **`markdown example`**
          MARKDOWN
        )
      end
    end

    context 'with metrics_dashboard_url' do
      before do
        allow(alert.parsed_payload).to receive(:metrics_dashboard_url).and_return('https://gitlab.com/metrics')
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **Severity:** #{presenter.severity}#{markdown_line_break}
            **GitLab alert:** #{alert_url}

            [](https://gitlab.com/metrics)
          MARKDOWN
        )
      end
    end
  end

  describe '#start_time' do
    it 'formats the start time of the alert' do
      alert.started_at = Time.utc(2019, 5, 5)

      expect(presenter.start_time). to eq('05 May 2019, 12:00AM (UTC)')
    end
  end

  describe '#details_url' do
    it 'returns the details URL' do
      expect(presenter.details_url).to match(%r{#{project.web_url}/-/alert_management/#{alert.iid}/details})
    end
  end

  describe '#details' do
    subject { presenter.details }

    it 'renders the payload as inline hash' do
      is_expected.to eq(
        'title' => 'Alert title',
        'start_time' => '2020-04-27T10:10:22.265949279Z',
        'custom.alert.fields' => %w[one two],
        'yet.another' => 73
      )
    end
  end
end
