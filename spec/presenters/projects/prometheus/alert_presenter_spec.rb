# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::AlertPresenter do
  let_it_be(:project, reload: true) { create(:project) }

  let(:presenter) { described_class.new(alert) }
  let(:payload) { {} }
  let(:alert) { create(:alerting_alert, project: project, payload: payload) }

  shared_context 'gitlab alert' do
    let(:gitlab_alert) { create(:prometheus_alert, project: project) }
    let(:metric_id) { gitlab_alert.prometheus_metric_id }

    let(:alert) do
      create(:alerting_alert, project: project, metric_id: metric_id)
    end
  end

  describe '#project_full_path' do
    subject { presenter.project_full_path }

    it { is_expected.to eq(project.full_path) }
  end

  describe '#start_time' do
    subject { presenter.start_time }

    let(:starts_at) { '2020-10-31T14:02:04Z' }

    before do
      payload['startsAt'] = starts_at
    end

    context 'with valid utc datetime' do
      it { is_expected.to eq('31 October 2020, 2:02PM (UTC)') }

      context 'with admin time zone not UTC' do
        before do
          allow(Time).to receive(:zone).and_return(ActiveSupport::TimeZone.new('Perth'))
        end

        it { is_expected.to eq('31 October 2020, 2:02PM (UTC)') }
      end
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

            **Start time:** #{presenter.start_time}

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

            **Start time:** #{presenter.start_time}

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

            **Start time:** #{presenter.start_time}#{markdown_line_break}
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

            **Start time:** #{presenter.start_time}#{markdown_line_break}
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

            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **Hosts:** http://localhost:3000

            MARKDOWN
          )
        end
      end
    end

    context 'with embedded metrics' do
      let(:starts_at) { '2018-03-12T09:06:00Z' }

      shared_examples_for 'markdown with metrics embed' do
        let(:expected_markdown) do
          <<~MARKDOWN.chomp
          #### Summary

          **Start time:** #{presenter.start_time}#{markdown_line_break}
          **full_query:** `avg(metric) > 1.0`

          [](#{url})
          MARKDOWN
        end

        context 'without a starting time available' do
          around do |example|
            Timecop.freeze(starts_at) { example.run }
          end

          it { is_expected.to eq(expected_markdown) }
        end

        context 'with a starting time available' do
          before do
            payload['startsAt'] = starts_at
          end

          it { is_expected.to eq(expected_markdown) }
        end
      end

      context 'for gitlab-managed prometheus alerts' do
        let(:gitlab_alert) { create(:prometheus_alert, project: project) }
        let(:metric_id) { gitlab_alert.prometheus_metric_id }
        let(:env_id) { gitlab_alert.environment_id }

        before do
          payload['labels'] = { 'gitlab_alert_id' => metric_id }
        end

        let(:url) { "http://localhost/#{project.full_path}/prometheus/alerts/#{metric_id}/metrics_dashboard?end=2018-03-12T09%3A36%3A00Z&environment_id=#{env_id}&start=2018-03-12T08%3A36%3A00Z" }

        it_behaves_like 'markdown with metrics embed'
      end

      context 'for alerts from a self-managed prometheus' do
        let!(:environment) { create(:environment, project: project, name: 'production') }
        let(:url) { "http://localhost/#{project.full_path}/-/environments/#{environment.id}/metrics_dashboard?embed_json=#{CGI.escape(embed_content.to_json)}&end=2018-03-12T09%3A36%3A00Z&start=2018-03-12T08%3A36%3A00Z" }

        let(:title) { 'title' }
        let(:y_label) { 'y_label' }
        let(:query) { 'avg(metric) > 1.0' }
        let(:embed_content) do
          {
            panel_groups: [{
              panels: [{
                type: 'line-graph',
                title: title,
                y_label: y_label,
                metrics: [{ query_range: query }]
              }]
            }]
          }
        end

        before do
          # Setup embed time range
          payload['startsAt'] = starts_at

          # Setup query
          payload['generatorURL'] = "http://host?g0.expr=#{CGI.escape(query)}"

          # Setup environment
          payload['labels'] ||= {}
          payload['labels']['gitlab_environment_name'] = 'production'

          # Setup chart title & axis labels
          payload['annotations'] ||= {}
          payload['annotations']['title'] = 'title'
          payload['annotations']['gitlab_y_label'] = 'y_label'
        end

        it_behaves_like 'markdown with metrics embed'

        context 'without y_label' do
          let(:y_label) { title }

          before do
            payload['annotations'].delete('gitlab_y_label')
          end

          it_behaves_like 'markdown with metrics embed'
        end

        context 'when not enough information is present for an embed' do
          let(:expected_markdown) do
            <<~MARKDOWN.chomp
            #### Summary

            **Start time:** #{presenter.start_time}#{markdown_line_break}
            **full_query:** `avg(metric) > 1.0`

            MARKDOWN
          end

          context 'without title' do
            before do
              payload['annotations'].delete('title')
            end

            it { is_expected.to eq(expected_markdown) }
          end

          context 'without environment' do
            before do
              payload['labels'].delete('gitlab_environment_name')
            end

            it { is_expected.to eq(expected_markdown) }
          end

          context 'without full_query' do
            let(:expected_markdown) do
              <<~MARKDOWN.chomp
              #### Summary

              **Start time:** #{presenter.start_time}

              MARKDOWN
            end

            before do
              payload.delete('generatorURL')
            end

            it { is_expected.to eq(expected_markdown) }
          end
        end
      end
    end
  end

  describe '#show_performance_dashboard_link?' do
    subject { presenter.show_performance_dashboard_link? }

    it { is_expected.to be_falsey }

    context 'with gitlab alert' do
      include_context 'gitlab alert'

      it { is_expected.to eq(true) }
    end
  end

  describe '#show_incident_issues_link?' do
    subject { presenter.show_incident_issues_link? }

    it { is_expected.to be_falsey }

    context 'create issue setting enabled' do
      before do
        create(:project_incident_management_setting, project: project, create_issue: true)
      end

      it { is_expected.to eq(true) }
    end
  end

  context 'with gitlab alert' do
    include_context 'gitlab alert'

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

    describe '#incident_issues_link' do
      let(:expected_link) do
        Gitlab::Routing.url_helpers
          .project_issues_url(project, label_name: described_class::INCIDENT_LABEL_NAME)
      end

      subject { presenter.incident_issues_link }

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
