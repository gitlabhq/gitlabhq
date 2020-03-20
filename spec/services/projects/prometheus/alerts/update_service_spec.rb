# frozen_string_literal: true

require 'spec_helper'

describe Projects::Prometheus::Alerts::UpdateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:environment) { create(:environment, project: project) }

  let_it_be(:alert) do
    create(:prometheus_alert, project: project, environment: environment)
  end

  let(:service) { described_class.new(project, user, params) }

  let(:params) do
    {
      environment_id: alert.environment_id,
      prometheus_metric_id: alert.prometheus_metric_id,
      operator: '==',
      threshold: 2.0
    }
  end

  describe '#execute' do
    subject { service.execute(alert) }

    context 'with valid params' do
      it 'updates the alert' do
        expect(subject).to be_truthy

        expect(alert.reload).to have_attributes(
          operator: 'eq',
          threshold: 2.0
        )
      end
    end

    context 'with invalid params' do
      let(:other_environment) { create(:environment) }

      before do
        params[:environment_id] = other_environment.id
      end

      it 'fails to update' do
        expect(subject).to be_falsey

        expect(alert).to be_invalid
      end
    end
  end
end
