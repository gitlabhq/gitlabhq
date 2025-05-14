# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Metrics::CiDeletedObjectProcessingSlis, feature_category: :continuous_integration do
  let(:possible_labels) { ::Gitlab::Metrics::CiDeletedObjectProcessingSlis::POSSIBLE_LABELS }
  let(:category_label) { ::Gitlab::Metrics::CiDeletedObjectProcessingSlis::CATEGORY_LABEL }

  describe '#initialize_slis!' do
    it 'initializes Apdex and ErrorRate SLIs for loose_foreign_key_clean_ups' do
      expect(::Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :ci_deleted_objects_processing,
        possible_labels
      )

      expect(::Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :ci_deleted_objects_processing,
        possible_labels
      )

      described_class.initialize_slis!
    end
  end

  describe '#record_apdex' do
    context 'with success: true' do
      it 'increments the ci_deleted_objects_processing Apdex as a success' do
        expect(Gitlab::Metrics::Sli::Apdex[:ci_deleted_objects_processing]).to receive(:increment).with(
          labels: category_label,
          success: true
        )

        described_class.record_apdex(success: true)
      end
    end

    context 'with success: false' do
      it 'increments the ci_deleted_objects_processing Apdex as not a success' do
        expect(Gitlab::Metrics::Sli::Apdex[:ci_deleted_objects_processing]).to receive(:increment).with(
          labels: category_label,
          success: false
        )

        described_class.record_apdex(success: false)
      end
    end
  end

  describe '#record_error' do
    context 'with error: true' do
      it 'increments the ci_deleted_objects_processing ErrorRate as an error' do
        expect(Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing]).to receive(:increment).with(
          labels: category_label,
          error: true
        )

        described_class.record_error(error: true)
      end
    end

    context 'with error: false' do
      it 'increments the ci_deleted_objects_processing ErrorRate as not an error' do
        expect(Gitlab::Metrics::Sli::ErrorRate[:ci_deleted_objects_processing]).to receive(:increment).with(
          labels: category_label,
          error: false
        )

        described_class.record_error(error: false)
      end
    end
  end
end
