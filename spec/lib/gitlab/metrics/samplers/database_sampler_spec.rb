# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Samplers::DatabaseSampler do
  subject { described_class.new }

  it_behaves_like 'metrics sampler', 'DATABASE_SAMPLER'

  describe '#sample' do
    let(:active_record_labels) do
      {
        class: 'ActiveRecord::Base',
        host: ApplicationRecord.database.config['host'],
        port: ApplicationRecord.database.config['port'],
        db_config_name: 'main'
      }
    end

    let(:ci_application_record_labels) do
      {
        class: 'Ci::ApplicationRecord',
        host: Ci::ApplicationRecord.database.config['host'],
        port: Ci::ApplicationRecord.database.config['port'],
        db_config_name: 'ci'
      }
    end

    before do
      described_class::METRIC_DESCRIPTIONS.each_key do |metric|
        allow(subject.metrics[metric]).to receive(:set)
      end

      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return({ main: ActiveRecord::Base, ci: Ci::ApplicationRecord })
    end

    context 'when the database is connected', :add_ci_connection do
      it 'samples connection pool statistics' do
        expect(subject.metrics[:size]).to receive(:set).with(active_record_labels, a_value >= 1)
        expect(subject.metrics[:connections]).to receive(:set).with(active_record_labels, a_value >= 1)
        expect(subject.metrics[:busy]).to receive(:set).with(active_record_labels, a_value >= 1)
        expect(subject.metrics[:dead]).to receive(:set).with(active_record_labels, a_value >= 0)
        expect(subject.metrics[:waiting]).to receive(:set).with(active_record_labels, a_value >= 0)

        expect(subject.metrics[:size]).to receive(:set).with(ci_application_record_labels, a_value >= 1)
        expect(subject.metrics[:connections]).to receive(:set).with(ci_application_record_labels, a_value >= 1)
        expect(subject.metrics[:busy]).to receive(:set).with(ci_application_record_labels, a_value >= 1)
        expect(subject.metrics[:dead]).to receive(:set).with(ci_application_record_labels, a_value >= 0)
        expect(subject.metrics[:waiting]).to receive(:set).with(ci_application_record_labels, a_value >= 0)

        subject.sample
      end
    end

    context 'when a database is not connected', :add_ci_connection do
      before do
        allow(Ci::ApplicationRecord).to receive(:connected?).and_return(false)
      end

      it 'records no samples for that database' do
        expect(subject.metrics[:size]).to receive(:set).with(active_record_labels, anything)
        expect(subject.metrics[:size]).not_to receive(:set).with(ci_application_record_labels, anything)

        subject.sample
      end
    end
  end
end
