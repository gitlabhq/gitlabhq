# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertPresenter do
  let_it_be(:project) { create(:project) }

  let(:presenter) { described_class.new(alert) }
  let(:payload) { {} }
  let(:alert) { create(:alerting_alert, project: project, payload: payload) }

  describe '#project_full_path' do
    subject { presenter.project_full_path }

    it { is_expected.to eq(project.full_path) }
  end

  describe '#starts_at' do
    subject { presenter.starts_at }

    before do
      payload['startsAt'] = starts_at
    end

    context 'with valid datetime' do
      let(:datetime) { Time.now }
      let(:starts_at) { datetime.rfc3339 }

      it { is_expected.to eq(datetime.rfc3339) }
    end

    context 'with invalid datetime' do
      let(:starts_at) { 'invalid' }

      it { is_expected.to be_nil }
    end
  end

  describe '#issue_summary_markdown' do
    let(:markdown_line_break) { '  ' }

    subject { presenter.issue_summary_markdown }

    context 'without default payload' do
      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}

          MARKDOWN
        )
      end
    end

    context 'with annotations' do
      before do
        payload['annotations'] = { 'title' => 'Alert Title', 'foo' => 'value1', 'bar' => 'value2' }
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}

            #### Alert Details

            **foo:** value1#{markdown_line_break}
            **bar:** value2
          MARKDOWN
        )
      end
    end

    context 'with full query' do
      before do
        payload['generatorURL'] = 'http://host?g0.expr=query'
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}#{markdown_line_break}
            **full_query:** `query`

          MARKDOWN
        )
      end
    end

    context 'with the Generic Alert parameters' do
      let(:generic_alert_params) do
        {
          'title' => 'The Generic Alert Title',
          'description' => 'The Generic Alert Description',
          'monitoring_tool' => 'monitoring_tool_name',
          'service' => 'service_name',
          'hosts' => ['http://localhost:3000', 'http://localhost:3001']
        }
      end

      before do
        payload['annotations'] = generic_alert_params
      end

      it do
        is_expected.to eq(
          <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}#{markdown_line_break}
            **Service:** service_name#{markdown_line_break}
            **Monitoring tool:** monitoring_tool_name#{markdown_line_break}
            **Hosts:** http://localhost:3000 http://localhost:3001

            #### Alert Details

            **description:** The Generic Alert Description
          MARKDOWN
        )
      end

      context 'when hosts is a string' do
        before do
          payload['annotations'] = { 'hosts' => 'http://localhost:3000' }
        end

        it do
          is_expected.to eq(
            <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.starts_at}#{markdown_line_break}
            **Hosts:** http://localhost:3000

            MARKDOWN
          )
        end
      end
    end
  end

  context 'with gitlab alert' do
    let(:gitlab_alert) { create(:prometheus_alert, project: project) }
    let(:metric_id) { gitlab_alert.prometheus_metric_id }

    let(:alert) do
      create(:alerting_alert, project: project, metric_id: metric_id)
    end

    describe '#full_title' do
      let(:query_title) do
        "#{gitlab_alert.title} #{gitlab_alert.computed_operator} #{gitlab_alert.threshold} for 5 minutes"
      end

      let(:expected_subject) do
        "#{alert.environment.name}: #{query_title}"
      end

      subject { presenter.full_title }

      it { is_expected.to eq(expected_subject) }
    end

    describe '#metric_query' do
      subject { presenter.metric_query }

      it { is_expected.to eq(gitlab_alert.full_query) }
    end

    describe '#environment_name' do
      subject { presenter.environment_name }

      it { is_expected.to eq(alert.environment.name) }
    end

    describe '#performance_dashboard_link' do
      let(:expected_link) do
        Gitlab::Routing.url_helpers
          .metrics_project_environment_url(project, alert.environment)
      end

      subject { presenter.performance_dashboard_link }

      it { is_expected.to eq(expected_link) }
    end
  end

  context 'without gitlab alert' do
    describe '#full_title' do
      subject { presenter.full_title }

      context 'with title' do
        let(:title) { 'some title' }

        before do
          expect(alert).to receive(:title).and_return(title)
        end

        it { is_expected.to eq(title) }
      end

      context 'without title' do
        it { is_expected.to eq('') }
      end
    end

    describe '#metric_query' do
      subject { presenter.metric_query }

      it { is_expected.to be_nil }
    end

    describe '#environment_name' do
      subject { presenter.environment_name }

      it { is_expected.to be_nil }
    end

    describe '#performance_dashboard_link' do
      let(:expected_link) do
        Gitlab::Routing.url_helpers.metrics_project_environments_url(project)
      end

      subject { presenter.performance_dashboard_link }

      it { is_expected.to eq(expected_link) }
    end
  end
end
