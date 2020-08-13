# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Validator::PostSchemaValidator do
  describe '#validate' do
    context 'with no project and dashboard_path provided' do
      context 'unique local metric_ids' do
        it 'returns empty array' do
          expect(described_class.new(metric_ids: [1, 2, 3]).validate).to eq([])
        end
      end

      context 'duplicate local metrics_ids' do
        it 'returns error' do
          expect(described_class.new(metric_ids: [1, 1]).validate)
            .to eq([Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds])
        end
      end
    end

    context 'with project and dashboard_path' do
      let(:project) { create(:project) }

      subject do
        described_class.new(
          project: project,
          metric_ids: ['some_identifier'],
          dashboard_path: 'test/path.yml'
        ).validate
      end

      context 'with unique metric identifiers' do
        before do
          create(:prometheus_metric,
            project: project,
            identifier: 'some_other_identifier',
            dashboard_path: 'test/path.yml'
          )
        end

        it 'returns empty array' do
          expect(subject).to eq([])
        end
      end

      context 'duplicate metric identifiers in database' do
        context 'with different dashboard_path' do
          before do
            create(:prometheus_metric,
              project: project,
              identifier: 'some_identifier',
              dashboard_path: 'some/other/path.yml'
            )
          end

          it 'returns error' do
            expect(subject).to include(Gitlab::Metrics::Dashboard::Validator::Errors::DuplicateMetricIds)
          end
        end

        context 'with same dashboard_path' do
          before do
            create(:prometheus_metric,
              project: project,
              identifier: 'some_identifier',
              dashboard_path: 'test/path.yml'
            )
          end

          it 'returns empty array' do
            expect(subject).to eq([])
          end
        end
      end
    end
  end
end
