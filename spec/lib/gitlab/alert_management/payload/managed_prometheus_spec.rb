# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload::ManagedPrometheus do
  let_it_be(:project) { create(:project) }

  let(:raw_payload) { {} }

  let(:parsed_payload) { described_class.new(project: project, payload: raw_payload) }

  it_behaves_like 'subclass has expected api'

  shared_context 'with gitlab alert' do
    let_it_be(:gitlab_alert) { create(:prometheus_alert, project: project) }
    let(:metric_id) { gitlab_alert.prometheus_metric_id.to_s }
    let(:alert_id) { gitlab_alert.id.to_s }
  end

  describe '#metric_id' do
    subject { parsed_payload.metric_id }

    it { is_expected.to be_nil }

    context 'with gitlab_alert_id' do
      let(:raw_payload) { { 'labels' => { 'gitlab_alert_id' => '12' } } }

      it { is_expected.to eq(12) }
    end
  end

  describe '#gitlab_prometheus_alert_id' do
    subject { parsed_payload.gitlab_prometheus_alert_id }

    it { is_expected.to be_nil }

    context 'with gitlab_alert_id' do
      let(:raw_payload) { { 'labels' => { 'gitlab_prometheus_alert_id' => '12' } } }

      it { is_expected.to eq(12) }
    end
  end

  describe '#gitlab_alert' do
    subject { parsed_payload.gitlab_alert }

    context 'without alert info in payload' do
      it { is_expected.to be_nil }
    end

    context 'with metric id in payload' do
      let(:raw_payload) { { 'labels' => { 'gitlab_alert_id' => metric_id } } }
      let(:metric_id) { '-1' }

      context 'without matching alert' do
        it { is_expected.to be_nil }
      end

      context 'with matching alert' do
        include_context 'with gitlab alert'

        it { is_expected.to eq(gitlab_alert) }

        context 'when unclear which alert applies' do
          # With multiple alerts for different environments,
          # we can't be sure which prometheus alert the payload
          # belongs to
          let_it_be(:another_alert) do
            create(:prometheus_alert,
                    prometheus_metric: gitlab_alert.prometheus_metric,
                    project: project)
          end

          it { is_expected.to be_nil }
        end
      end
    end

    context 'with alert id' do
      # gitlab_prometheus_alert_id is a stronger identifier,
      # but was added after gitlab_alert_id; we won't
      # see it without gitlab_alert_id also present
      let(:raw_payload) do
        {
          'labels' => {
            'gitlab_alert_id' => metric_id,
            'gitlab_prometheus_alert_id' => alert_id
          }
        }
      end

      context 'without matching alert' do
        let(:alert_id) { '-1' }
        let(:metric_id) { '-1' }

        it { is_expected.to be_nil }
      end

      context 'with matching alerts' do
        include_context 'with gitlab alert'

        it { is_expected.to eq(gitlab_alert) }
      end
    end
  end

  describe '#full_query' do
    subject { parsed_payload.full_query }

    it { is_expected.to be_nil }

    context 'with gitlab alert' do
      include_context 'with gitlab alert'

      let(:raw_payload) { { 'labels' => { 'gitlab_alert_id' => metric_id } } }

      it { is_expected.to eq(gitlab_alert.full_query) }
    end

    context 'with sufficient fallback info' do
      let(:raw_payload) { { 'generatorURL' => 'http://localhost:9090/graph?g0.expr=vector%281%29' } }

      it { is_expected.to eq('vector(1)') }
    end
  end

  describe '#environment' do
    subject { parsed_payload.environment }

    context 'with gitlab alert' do
      include_context 'with gitlab alert'

      let(:raw_payload) { { 'labels' => { 'gitlab_alert_id' => metric_id } } }

      it { is_expected.to eq(gitlab_alert.environment) }
    end

    context 'with sufficient fallback info' do
      let_it_be(:environment) { create(:environment, project: project, name: 'production') }

      let(:raw_payload) do
        {
          'labels' => {
            'gitlab_alert_id' => '-1',
            'gitlab_environment_name' => 'production'
          }
        }
      end

      it { is_expected.to eq(environment) }
    end
  end

  describe '#metrics_dashboard_url' do
    subject { parsed_payload.metrics_dashboard_url }

    context 'without alert' do
      it { is_expected.to be_nil }
    end

    context 'with gitlab alert' do
      include_context 'gitlab-managed prometheus alert attributes' do
        let(:raw_payload) { payload }
      end

      it { is_expected.to eq(dashboard_url_for_alert) }
    end
  end
end
