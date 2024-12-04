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
    shared_examples 'setting class attributes' do
      context 'when the attribute is set' do
        before do
          worker.public_send(setter, *values, **kwargs)
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
          child_worker.public_send(setter, *values, **kwargs)
        end

        it 'returns the default value for the parent, and the expected value for the child' do
          expect(worker.public_send(getter)).to eq(default)
          expect(child_worker.public_send(getter)).to eq(expected)
        end
      end
    end

    # rubocop: disable Layout/LineLength -- using table synxax
    where(:getter, :setter, :default, :values, :kwargs, :expected) do
      :worker_has_external_dependencies?      | :worker_has_external_dependencies! | false            | [] | {} | true
      :idempotent?                            | :idempotent!                       | false            | [] | {} | true
      :big_payload?                           | :big_payload!                      | false            | [] | {} | true

      :get_feature_category                   | :feature_category                  | nil              | [:foo]       | {} | :foo
      :get_urgency                            | :urgency                           | :low             | [:high]      | {} | :high
      :get_worker_resource_boundary           | :worker_resource_boundary          | :unknown         | [:cpu]       | {} | :cpu
      :get_weight                             | :weight                            | 1                | [3]          | {} | 3
      :get_tags                               | :tags                              | []               | [:foo, :bar] | {} | [:foo, :bar]
      :get_deduplicate_strategy               | :deduplicate                       | :until_executing | [:none]      | {} | :none

      :get_deduplication_options              | :deduplicate                       | {}               | [:none, { including_scheduled: true }] | {} | { including_scheduled: true }
      :database_health_check_attrs            | :defer_on_database_health_signal   | nil              | [:gitlab_main, [:users], 1.minute]     | {} | { gitlab_schema: :gitlab_main, tables: [:users], delay_by: 1.minute, block: nil }
    end
    # rubocop: enable Layout/LineLength

    with_them do
      it_behaves_like 'setting class attributes'
    end

    context 'when using multiple databases' do
      before do
        skip_if_shared_database(:ci)
        skip_if_shared_database(:sec)
      end

      # rubocop: disable Layout/LineLength -- using table synxax
      where(:getter, :setter, :default, :values, :kwargs, :expected) do
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | { overrides: { ci: :delayed, main: :sticky } } | :delayed
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | {} | :always
        :get_data_consistency_per_database      | :data_consistency | { main: :always, ci: :always, sec: :always } | [:sticky] | { overrides: { ci: :delayed } } | { ci: :delayed, main: :sticky, sec: :sticky }
        :get_data_consistency_per_database      | :data_consistency | { main: :always, ci: :always, sec: :always } | [:sticky] | {} | { ci: :sticky, main: :sticky, sec: :sticky }
      end
      # rubocop: enable Layout/LineLength

      with_them do
        it_behaves_like 'setting class attributes'
      end
    end

    context 'when using a single database with ci connection' do
      before do
        skip_if_database_exists(:ci)
        skip_if_database_exists(:sec)
        skip_if_multiple_databases_not_setup(:ci)
      end

      # rubocop: disable Layout/LineLength -- using table synxax
      where(:getter, :setter, :default, :values, :kwargs, :expected) do
        :get_data_consistency_per_database      | :data_consistency | { main: :always, ci: :always } | [:sticky] | { overrides: { ci: :delayed } } | { main: :sticky, ci: :sticky }
        :get_data_consistency_per_database      | :data_consistency | { main: :always, ci: :always } | [:sticky] | {} | { main: :sticky, ci: :sticky }
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | { overrides: { ci: :delayed, main: :sticky } } | :always
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | {} | :always
      end
      # rubocop: enable Layout/LineLength

      with_them do
        it_behaves_like 'setting class attributes'
      end
    end

    context 'when using a single database' do
      before do
        skip_if_database_exists(:ci)
        skip_if_database_exists(:sec)
        skip_if_multiple_databases_are_setup(:ci, :sec)
      end

      # rubocop: disable Layout/LineLength -- using table synxax
      where(:getter, :setter, :default, :values, :kwargs, :expected) do
        :get_data_consistency_per_database      | :data_consistency | { main: :always } | [:sticky] | { overrides: { ci: :delayed, sec: :delayed } } | { main: :sticky }
        :get_data_consistency_per_database      | :data_consistency | { main: :always } | [:sticky] | {} | { main: :sticky }
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | { overrides: { ci: :delayed, main: :sticky, sec: :delayed } } | :always
        :get_least_restrictive_data_consistency | :data_consistency | :always | [:always] | {} | :always
      end
      # rubocop: enable Layout/LineLength

      with_them do
        it_behaves_like 'setting class attributes'
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

    context 'with invalid data_consistency in overrides' do
      it 'raises exception' do
        expect { worker.data_consistency(:always, overrides: { ci: :invalid }) }
          .to raise_error('Invalid data consistency: {:ci=>:invalid}')
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

    context 'when overrides are provided in a single database setup' do
      before do
        skip_if_database_exists(:ci)
        skip_if_database_exists(:sec)
        skip_if_multiple_databases_are_setup(:ci, :sec)
      end

      it 'returns correct feature flag value' do
        worker.data_consistency(:always, overrides: { ci: :delayed })

        expect(worker.get_data_consistency_per_database).to eq({ main: :always })
      end

      context 'when feature_flag is provided' do
        before do
          skip_default_enabled_yaml_check
        end

        context 'when feature_flag is disable' do
          before do
            stub_feature_flags(test_feature_flag: false)
          end

          it 'returns correct feature flag value' do
            worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

            expect(worker.get_data_consistency_per_database).to eq({ main: :always })
            expect(worker.get_least_restrictive_data_consistency).to eq(:always)
          end
        end

        it 'returns correct feature flag value' do
          worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

          expect(worker.get_data_consistency_per_database).to eq({ main: :always })
          expect(worker.get_least_restrictive_data_consistency).to eq(:always)
        end
      end
    end

    context 'when overrides are provided in a single database setup with ci connection' do
      before do
        skip_if_database_exists(:ci)
        skip_if_multiple_databases_not_setup(:ci)
      end

      it 'returns correct feature flag value' do
        worker.data_consistency(:always, overrides: { ci: :delayed })

        expect(worker.get_data_consistency_per_database).to eq({ ci: :always, main: :always })
      end

      context 'when feature_flag is provided' do
        before do
          skip_default_enabled_yaml_check
        end

        context 'when feature_flag is disable' do
          before do
            stub_feature_flags(test_feature_flag: false)
          end

          it 'returns correct feature flag value' do
            worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

            expect(worker.get_data_consistency_per_database).to eq({ main: :always, ci: :always })
            expect(worker.get_least_restrictive_data_consistency).to eq(:always)
          end
        end

        it 'returns correct feature flag value' do
          worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

          expect(worker.get_data_consistency_per_database).to eq({ ci: :always, main: :always })
          expect(worker.get_least_restrictive_data_consistency).to eq(:always)
        end
      end
    end

    context 'when overrides are provided in a multi database setup' do
      before do
        skip_if_shared_database(:ci)
        skip_if_shared_database(:sec)
        skip_if_multiple_databases_not_setup(:sec)
      end

      it 'returns correct feature flag value' do
        worker.data_consistency(:always, overrides: { ci: :delayed })

        expect(worker.get_data_consistency_per_database).to eq({ ci: :delayed, main: :always, sec: :always })
      end

      context 'when feature_flag is provided' do
        before do
          skip_default_enabled_yaml_check
        end

        context 'when feature_flag is disable' do
          before do
            stub_feature_flags(test_feature_flag: false)
          end

          it 'returns correct feature flag value' do
            worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

            expect(worker.get_data_consistency_per_database).to eq({ main: :always, ci: :always, sec: :always })
            expect(worker.get_least_restrictive_data_consistency).to eq(:always)
          end
        end

        it 'returns correct feature flag value' do
          worker.data_consistency(:always, feature_flag: :test_feature_flag, overrides: { ci: :delayed })

          expect(worker.get_data_consistency_per_database).to eq({ ci: :delayed, main: :always, sec: :always })
          expect(worker.get_least_restrictive_data_consistency).to eq(:delayed)
        end
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
