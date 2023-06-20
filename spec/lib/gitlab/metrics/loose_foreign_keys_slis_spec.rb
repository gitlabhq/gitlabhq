# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Metrics::LooseForeignKeysSlis do
  # This needs to be dynamic because db_config_names depends on
  # config/database.yml and the specs need to work for all configurations. That
  # means this assertion is a copy of the implementation.
  let(:possible_labels) do
    ::Gitlab::Database.db_config_names(with_schema: :gitlab_shared).map do |db_config_name|
      {
        db_config_name: db_config_name,
        feature_category: :database
      }
    end
  end

  describe '#initialize_slis!' do
    it 'initializes Apdex and ErrorRate SLIs for loose_foreign_key_clean_ups' do
      expect(::Gitlab::Metrics::Sli::Apdex).to receive(:initialize_sli).with(
        :loose_foreign_key_clean_ups,
        possible_labels
      )

      expect(::Gitlab::Metrics::Sli::ErrorRate).to receive(:initialize_sli).with(
        :loose_foreign_key_clean_ups,
        possible_labels
      )

      described_class.initialize_slis!
    end
  end

  describe '#record_apdex' do
    context 'with success: true' do
      it 'increments the loose_foreign_key_clean_ups Apdex as a success' do
        expect(Gitlab::Metrics::Sli::Apdex[:loose_foreign_key_clean_ups]).to receive(:increment).with(
          labels: { feature_category: :database, db_config_name: 'main' },
          success: true
        )

        described_class.record_apdex(success: true, db_config_name: 'main')
      end
    end

    context 'with success: false' do
      it 'increments the loose_foreign_key_clean_ups Apdex as not a success' do
        expect(Gitlab::Metrics::Sli::Apdex[:loose_foreign_key_clean_ups]).to receive(:increment).with(
          labels: { feature_category: :database, db_config_name: 'main' },
          success: false
        )

        described_class.record_apdex(success: false, db_config_name: 'main')
      end
    end
  end

  describe '#record_error_rate' do
    context 'with error: true' do
      it 'increments the loose_foreign_key_clean_ups ErrorRate as an error' do
        expect(Gitlab::Metrics::Sli::ErrorRate[:loose_foreign_key_clean_ups]).to receive(:increment).with(
          labels: { feature_category: :database, db_config_name: 'main' },
          error: true
        )

        described_class.record_error_rate(error: true, db_config_name: 'main')
      end
    end

    context 'with error: false' do
      it 'increments the loose_foreign_key_clean_ups ErrorRate as not an error' do
        expect(Gitlab::Metrics::Sli::ErrorRate[:loose_foreign_key_clean_ups]).to receive(:increment).with(
          labels: { feature_category: :database, db_config_name: 'main' },
          error: false
        )

        described_class.record_error_rate(error: false, db_config_name: 'main')
      end
    end
  end
end
