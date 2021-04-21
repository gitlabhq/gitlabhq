# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PrometheusAlertPresenter do
  let_it_be(:project) { create(:project) }
  let_it_be(:environment) { create(:environment, project: project) }

  let(:presenter) { described_class.new(prometheus_alert) }

  describe '#humanized_text' do
    subject { presenter.humanized_text }

    let_it_be(:prometheus_metric) { create(:prometheus_metric, project: project) }

    let(:prometheus_alert) { create(:prometheus_alert, operator: operator, project: project, environment: environment, prometheus_metric: prometheus_metric) }
    let(:operator) { :gt }

    it { is_expected.to eq('exceeded 1.0m/s') }

    context 'when operator is eq' do
      let(:operator) { :eq }

      it { is_expected.to eq('is equal to 1.0m/s') }
    end

    context 'when operator is lt' do
      let(:operator) { :lt }

      it { is_expected.to eq('is less than 1.0m/s') }
    end
  end
end
