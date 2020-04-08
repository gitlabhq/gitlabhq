# frozen_string_literal: true

require 'spec_helper'

describe Prometheus::CreateDefaultAlertsService do
  let_it_be(:project) { create(:project) }
  let(:instance) { described_class.new(project: project) }
  let(:expected_alerts) { described_class::DEFAULT_ALERTS }

  describe '#execute' do
    subject(:execute) { instance.execute }

    shared_examples 'no alerts created' do
      it 'does not create alerts' do
        expect { execute }.not_to change { project.reload.prometheus_alerts.count }
      end
    end

    context 'no environment' do
      it_behaves_like 'no alerts created'
    end

    context 'environment exists' do
      let_it_be(:environment) { create(:environment, project: project) }

      context 'no found metric' do
        it_behaves_like 'no alerts created'
      end

      context 'metric exists' do
        before do
          create_expected_metrics!
        end

        context 'alert exists already' do
          before do
            create_pre_existing_alerts!(environment)
          end

          it_behaves_like 'no alerts created'
        end

        it 'creates alerts' do
          expect { execute }.to change { project.reload.prometheus_alerts.count }
           .by(expected_alerts.size)
        end

        context 'multiple environments' do
          let!(:production) { create(:environment, project: project, name: 'production') }

          it 'uses the production environment' do
            expect { execute }.to change { production.reload.prometheus_alerts.count }
              .by(expected_alerts.size)
          end
        end
      end
    end
  end

  private

  def create_expected_metrics!
    expected_alerts.each do |alert_hash|
      create(:prometheus_metric, :common, identifier: alert_hash.fetch(:identifier))
    end
  end

  def create_pre_existing_alerts!(environment)
    expected_alerts.each do |alert_hash|
      metric = PrometheusMetric.for_identifier(alert_hash[:identifier]).first!
      create(:prometheus_alert, prometheus_metric: metric, project: project, environment: environment)
    end
  end
end
