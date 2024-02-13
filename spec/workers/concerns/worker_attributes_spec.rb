# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkerAttributes, feature_category: :shared do
  using RSpec::Parameterized::TableSyntax

  let(:worker) do
    Class.new do
      def self.name
        "TestWorker"
      end

      include ApplicationWorker
    end
  end

  let(:child_worker) do
    Class.new(worker) do
      def self.name
        "TestChildworker"
      end
    end
  end

  describe 'class attributes' do
    # rubocop: disable Layout/LineLength
    where(:getter, :setter, :default, :values, :expected) do
      :get_feature_category              | :feature_category                  | nil              | [:foo]                             | :foo
      :get_urgency                       | :urgency                           | :low             | [:high]                            | :high
      :get_data_consistency              | :data_consistency                  | :always          | [:sticky]                          | :sticky
      :get_worker_resource_boundary      | :worker_resource_boundary          | :unknown         | [:cpu]                             | :cpu
      :get_weight                        | :weight                            | 1                | [3]                                | 3
      :get_tags                          | :tags                              | []               | [:foo, :bar]                       | [:foo, :bar]
      :get_deduplicate_strategy          | :deduplicate                       | :until_executing | [:none]                            | :none
      :get_deduplication_options         | :deduplicate                       | {}               | [:none, including_scheduled: true] | { including_scheduled: true }
      :worker_has_external_dependencies? | :worker_has_external_dependencies! | false            | []                                 | true
      :idempotent?                       | :idempotent!                       | false            | []                                 | true
      :big_payload?                      | :big_payload!                      | false            | []                                 | true
      :database_health_check_attrs       | :defer_on_database_health_signal   | nil              | [:gitlab_main, [:users], 1.minute] | { gitlab_schema: :gitlab_main, tables: [:users], delay_by: 1.minute, block: nil }
    end
    # rubocop: enable Layout/LineLength

    with_them do
      context 'when the attribute is set' do
        before do
          worker.public_send(setter, *values)
        end

        it 'returns the expected value' do
          expect(worker.public_send(getter)).to eq(expected)
          expect(child_worker.public_send(getter)).to eq(expected)
        end
      end

      context 'when the attribute is not set' do
        it 'returns the default value' do
          expect(worker.public_send(getter)).to eq(default)
          expect(child_worker.public_send(getter)).to eq(default)
        end
      end

      context 'when the attribute is set in the child worker' do
        before do
          child_worker.public_send(setter, *values)
        end

        it 'returns the default value for the parent, and the expected value for the child' do
          expect(worker.public_send(getter)).to eq(default)
          expect(child_worker.public_send(getter)).to eq(expected)
        end
      end
    end
  end

  describe '.data_consistency' do
    context 'with invalid data_consistency' do
      it 'raises exception' do
        expect { worker.data_consistency(:invalid) }
          .to raise_error('Invalid data consistency: invalid')
      end
    end

    context 'when feature_flag is provided' do
      before do
        stub_feature_flags(test_feature_flag: false)
        skip_default_enabled_yaml_check
      end

      it 'returns correct feature flag value' do
        worker.data_consistency(:sticky, feature_flag: :test_feature_flag)

        expect(worker.get_data_consistency_feature_flag_enabled?).not_to be(true)
        expect(child_worker.get_data_consistency_feature_flag_enabled?).not_to be(true)
      end
    end
  end

  describe '#deduplication_enabled?' do
    subject(:deduplication_enabled?) { worker.deduplication_enabled? }

    context 'when no feature flag is set' do
      before do
        worker.deduplicate(:until_executing)
      end

      it 'returns true' do
        expect(worker.deduplication_enabled?).to be(true)
        expect(child_worker.deduplication_enabled?).to be(true)
      end
    end

    context 'when feature flag is set' do
      before do
        skip_default_enabled_yaml_check

        worker.deduplicate(:until_executing, feature_flag: :my_feature_flag)
      end

      context 'when the FF is enabled' do
        before do
          stub_feature_flags(my_feature_flag: true)
        end

        it 'returns true' do
          expect(worker.deduplication_enabled?).to be(true)
          expect(child_worker.deduplication_enabled?).to be(true)
        end
      end

      context 'when the FF is disabled' do
        before do
          stub_feature_flags(my_feature_flag: false)
        end

        it 'returns false' do
          expect(worker.deduplication_enabled?).to be(false)
          expect(child_worker.deduplication_enabled?).to be(false)
        end
      end
    end
  end

  describe '#defer_on_database_health_signal?' do
    subject(:defer_on_database_health_signal?) { worker.defer_on_database_health_signal? }

    context 'when defer_on_database_health_signal is set' do
      before do
        worker.defer_on_database_health_signal(:gitlab_main, [:users], 1.minute)
      end

      it { is_expected.to be(true) }
    end

    context 'when defer_on_database_health_signal is not set' do
      it { is_expected.to be(false) }
    end
  end
end
