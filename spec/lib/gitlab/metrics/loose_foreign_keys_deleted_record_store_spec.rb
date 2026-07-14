# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::LooseForeignKeysDeletedRecordStore, feature_category: :database do
  let(:counter) { instance_double(Prometheus::Client::Counter) }

  before do
    allow(Gitlab::Metrics).to receive_messages(counter: counter)
  end

  shared_examples 'a per-model write counter' do |method|
    it 'increments the counter per model', :aggregate_failures do
      per_model_counts = {
        'loose_foreign_keys_deleted_records' => 1,
        'loose_foreign_keys_organization_deleted_records' => 2
      }

      expect(counter).to receive(:increment).with({ model: 'loose_foreign_keys_deleted_records' }, 1)
      expect(counter).to receive(:increment).with({ model: 'loose_foreign_keys_organization_deleted_records' }, 2)

      described_class.public_send(method, per_model_counts)
    end
  end

  describe '.record_loaded' do
    it 'increments the loaded counter labeled by model and source table' do
      expect(counter).to(
        receive(:increment).with({ model: 'loose_foreign_keys_deleted_records', table: 'public.projects' }, 3)
      )

      described_class.record_loaded('loose_foreign_keys_deleted_records', 'public.projects', 3)
    end

    it 'increments with zero when a model returns no records' do
      expect(counter).to(
        receive(:increment).with({ model: 'loose_foreign_keys_user_deleted_records', table: 'public.projects' }, 0)
      )

      described_class.record_loaded('loose_foreign_keys_user_deleted_records', 'public.projects', 0)
    end
  end

  describe '.record_processed' do
    it_behaves_like 'a per-model write counter', :record_processed
  end

  describe '.record_rescheduled' do
    it_behaves_like 'a per-model write counter', :record_rescheduled
  end

  describe '.record_incremented' do
    it_behaves_like 'a per-model write counter', :record_incremented
  end
end
