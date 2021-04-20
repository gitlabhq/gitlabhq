# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::AlertManagement::Payload do
  describe '#parse' do
    let_it_be(:project) { build_stubbed(:project) }

    let(:payload) { {} }

    context 'without a monitoring_tool specified by caller' do
      subject { described_class.parse(project, payload) }

      context 'without a monitoring tool in the payload' do
        it { is_expected.to be_a Gitlab::AlertManagement::Payload::Generic }
      end

      context 'with the payload specifying Prometheus' do
        let(:payload) { { 'monitoring_tool' => 'Prometheus' } }

        it { is_expected.to be_a Gitlab::AlertManagement::Payload::Prometheus }

        context 'with gitlab-managed attributes' do
          let(:payload) { { 'monitoring_tool' => 'Prometheus', 'labels' => { 'gitlab_alert_id' => '12' } } }

          it { is_expected.to be_a Gitlab::AlertManagement::Payload::ManagedPrometheus }
        end
      end

      context 'with the payload specifying an unknown tool' do
        let(:payload) { { 'monitoring_tool' => 'Custom Tool' } }

        it { is_expected.to be_a Gitlab::AlertManagement::Payload::Generic }
      end
    end

    context 'with monitoring_tool specified by caller' do
      subject { described_class.parse(project, payload, monitoring_tool: monitoring_tool) }

      context 'as Prometheus' do
        let(:monitoring_tool) { 'Prometheus' }

        context 'with an externally managed prometheus payload' do
          it { is_expected.to be_a Gitlab::AlertManagement::Payload::Prometheus }
        end

        context 'with a self-managed prometheus payload' do
          let(:payload) { { 'labels' => { 'gitlab_alert_id' => '14' } } }

          it { is_expected.to be_a Gitlab::AlertManagement::Payload::ManagedPrometheus }
        end
      end

      context 'as an unknown tool' do
        let(:monitoring_tool) { 'Custom Tool' }

        it { is_expected.to be_a Gitlab::AlertManagement::Payload::Generic }
      end
    end

    context 'with integration specified by caller' do
      let(:integration) { instance_double(AlertManagement::HttpIntegration) }

      subject { described_class.parse(project, payload, integration: integration) }

      it 'passes an integration to a specific payload' do
        expect(::Gitlab::AlertManagement::Payload::Generic)
          .to receive(:new)
          .with(project: project, payload: payload, integration: integration)
          .and_call_original

        subject
      end
    end
  end
end
