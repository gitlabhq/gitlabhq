# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Metrics::CiDeletedObjectProcessingSlis, feature_category: :continuous_integration do
  let(:possible_labels) { described_class::POSSIBLE_LABELS }
  let(:category_label) { described_class::CATEGORY_LABEL }

  describe '#initialize_slis!' do
    it 'initializes ErrorRate SLI for ci_deleted_objects_processing' do
      expect(::Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :ci_deleted_objects_processing,
        possible_labels
      )

      described_class.initialize_slis!
    end
  end

  describe '#record_error' do
    it 'increments ErrorRate with error: true when deletion fails' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing]).to receive(:increment).with(
        labels: category_label,
        error: true
      )

      described_class.record_error(error: true)
    end

    it 'increments ErrorRate with error: false when deletion succeeds' do
      expect(Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing]).to receive(:increment).with(
        labels: category_label,
        error: false
      )

      described_class.record_error(error: false)
    end
  end

  describe '#track_deletion' do
    let(:object) { instance_double(Ci::DeletedObject, created_at: created_at) }
    let(:counter) { instance_double(Prometheus::Client::Counter) }

    before do
      described_class.instance_variable_set(:@deletions_counter, nil)
      allow(Gitlab::Metrics).to receive(:counter).and_call_original
      allow(Gitlab::Metrics).to receive(:counter)
        .with(:ci_deleted_objects_total, anything)
        .and_return(counter)
      allow(counter).to receive(:increment)
    end

    after do
      described_class.instance_variable_set(:@deletions_counter, nil)
    end

    context 'when object age is within acceptable delay' do
      let(:created_at) { 6.hours.ago }

      it 'increments counter with delayed: "false"' do
        expect(counter).to receive(:increment).with(delayed: "false", age_bucket: "4-8h")

        described_class.track_deletion(object)
      end
    end

    context 'when object age exceeds acceptable delay' do
      let(:created_at) { 36.hours.ago }

      it 'increments counter with delayed: "true"' do
        expect(counter).to receive(:increment).with(delayed: "true", age_bucket: "24-48h")

        described_class.track_deletion(object)
      end
    end

    it 'creates counter with correct name and description' do
      object = instance_double(Ci::DeletedObject, created_at: 1.hour.ago)

      expect(Gitlab::Metrics).to receive(:counter).with(
        :ci_deleted_objects_total,
        'Total number of CI deleted objects processed'
      ).and_return(counter)

      described_class.track_deletion(object)
    end
  end
end
