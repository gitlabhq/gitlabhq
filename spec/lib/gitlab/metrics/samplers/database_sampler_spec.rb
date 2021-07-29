# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::DatabaseSampler do
  subject { described_class.new }

  it_behaves_like 'metrics sampler', 'DATABASE_SAMPLER'

  describe '#sample' do
    before do
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        allow(subject.metrics[metric]).to receive(:set)
      end
    end

    context 'for ActiveRecord::Base' do
      let(:labels) do
        {
          class: 'ActiveRecord::Base',
          host: Gitlab::Database.main.config['host'],
          port: Gitlab::Database.main.config['port']
        }
      end

      context 'when the database is connected' do
        it 'samples connection pool statistics' do
          expect(subject.metrics[:size]).to receive(:set).with(labels, a_value >= 1)
          expect(subject.metrics[:connections]).to receive(:set).with(labels, a_value >= 1)
          expect(subject.metrics[:busy]).to receive(:set).with(labels, a_value >= 1)
          expect(subject.metrics[:dead]).to receive(:set).with(labels, a_value >= 0)
          expect(subject.metrics[:waiting]).to receive(:set).with(labels, a_value >= 0)

          subject.sample
        end
      end

      context 'when the database is not connected' do
        before do
          allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
        end

        it 'records no samples' do
          expect(subject.metrics[:size]).not_to receive(:set).with(labels, anything)

          subject.sample
        end
      end
    end
  end
end
