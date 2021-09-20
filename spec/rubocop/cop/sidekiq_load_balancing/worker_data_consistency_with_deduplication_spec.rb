# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'
require_relative '../../../../rubocop/cop/sidekiq_load_balancing/worker_data_consistency_with_deduplication'

RSpec.describe RuboCop::Cop::SidekiqLoadBalancing::WorkerDataConsistencyWithDeduplication do
  using RSpec::Parameterized::TableSyntax

  subject(:cop) { described_class.new }

  before do
    allow(cop)
      .to receive(:in_worker?)
      .and_return(true)
  end

  where(:data_consistency) { %i[delayed sticky] }

  with_them do
    let(:strategy) { described_class::DEFAULT_STRATEGY }
    let(:corrected) do
      <<~CORRECTED
      class SomeWorker
        include ApplicationWorker

        data_consistency :#{data_consistency}

        deduplicate #{strategy}, including_scheduled: true
        idempotent!
      end
      CORRECTED
    end

    context 'when deduplication strategy is not explicitly set' do
      it 'registers an offense and corrects using default strategy' do
        expect_offense(<<~CODE)
          class SomeWorker
            include ApplicationWorker

            data_consistency :#{data_consistency}

            idempotent!
            ^^^^^^^^^^^ Workers that declare either `:sticky` or `:delayed` data consistency [...]
          end
        CODE

        expect_correction(corrected)
      end

      context 'when identation is different' do
        let(:corrected) do
          <<~CORRECTED
            class SomeWorker
                include ApplicationWorker

                data_consistency :#{data_consistency}

                deduplicate #{strategy}, including_scheduled: true
                idempotent!
            end
          CORRECTED
        end

        it 'registers an offense and corrects with correct identation' do
          expect_offense(<<~CODE)
            class SomeWorker
                include ApplicationWorker

                data_consistency :#{data_consistency}

                idempotent!
                ^^^^^^^^^^^ Workers that declare either `:sticky` or `:delayed` data consistency [...]
            end
          CODE

          expect_correction(corrected)
        end
      end
    end

    context 'when deduplication strategy does not include including_scheduling option' do
      let(:strategy) { ':until_executed' }

      it 'registers an offense and corrects' do
        expect_offense(<<~CODE)
          class SomeWorker
            include ApplicationWorker

            data_consistency :#{data_consistency}

            deduplicate :until_executed
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Workers that declare either `:sticky` or `:delayed` data consistency [...]
            idempotent!
          end
        CODE

        expect_correction(corrected)
      end
    end

    context 'when deduplication strategy has including_scheduling option disabled' do
      let(:strategy) { ':until_executed' }

      it 'registers an offense and corrects' do
        expect_offense(<<~CODE)
          class SomeWorker
            include ApplicationWorker

            data_consistency :#{data_consistency}

            deduplicate :until_executed, including_scheduled: false
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Workers that declare either `:sticky` or `:delayed` data consistency [...]
            idempotent!
          end
        CODE

        expect_correction(corrected)
      end
    end

    context "when deduplication strategy is :none" do
      it 'does not register an offense' do
        expect_no_offenses(<<~CODE)
          class SomeWorker
            include ApplicationWorker

            data_consistency :always

            deduplicate :none
            idempotent!
          end
        CODE
      end
    end

    context "when deduplication strategy has including_scheduling option enabled" do
      it 'does not register an offense' do
        expect_no_offenses(<<~CODE)
          class SomeWorker
            include ApplicationWorker

            data_consistency :always

            deduplicate :until_executing, including_scheduled: true
            idempotent!
          end
        CODE
      end
    end
  end

  context "data_consistency: :always" do
    it 'does not register an offense' do
      expect_no_offenses(<<~CODE)
        class SomeWorker
          include ApplicationWorker

          data_consistency :always

          idempotent!
        end
      CODE
    end
  end
end
