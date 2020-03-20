# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }

  subject { service.execute }

  describe '#execute' do
    context 'with params' do
      let_it_be(:environment) { create(:environment, project: project) }

      let_it_be(:metric) do
        create(:prometheus_metric, project: project)
      end

      let(:params) do
        {
          environment_id: environment.id,
          prometheus_metric_id: metric.id,
          operator: '<',
          threshold: 1.0
        }
      end

      it 'creates an alert' do
        expect(subject).to be_persisted

        expect(subject).to have_attributes(
          project: project,
          environment: environment,
          prometheus_metric: metric,
          operator: 'lt',
          threshold: 1.0
        )
      end
    end

    context 'without params' do
      let(:params) { {} }

      it 'fails to create' do
        expect(subject).to be_new_record
        expect(subject).to be_invalid
      end
    end
  end
end
