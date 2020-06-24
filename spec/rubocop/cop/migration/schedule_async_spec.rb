# frozen_string_literal: true

require 'fast_spec_helper'

require 'rubocop'
require 'rubocop/rspec/support'

require_relative '../../../../rubocop/cop/migration/schedule_async'

RSpec.describe RuboCop::Cop::Migration::ScheduleAsync do
  include CopHelper

  let(:cop) { described_class.new }
  let(:source) do
    <<~SOURCE
      def up
        BackgroundMigrationWorker.perform_async(ClazzName, "Bar", "Baz")
      end
    SOURCE
  end

  shared_examples 'a disabled cop' do
    it 'does not register any offenses' do
      inspect_source(source)

      expect(cop.offenses).to be_empty
    end
  end

  context 'outside of a migration' do
    it_behaves_like 'a disabled cop'
  end

  context 'in a migration' do
    before do
      allow(cop).to receive(:in_migration?).and_return(true)
    end

    context 'in an old migration' do
      before do
        allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE - 5)
      end

      it_behaves_like 'a disabled cop'
    end

    context 'that is recent' do
      before do
        allow(cop).to receive(:version).and_return(described_class::ENFORCED_SINCE + 5)
      end

      context 'BackgroundMigrationWorker.perform_async' do
        it 'adds an offence when calling `BackgroundMigrationWorker.peform_async`' do
          inspect_source(source)

          expect(cop.offenses.size).to eq(1)
        end

        it 'autocorrects to the right version' do
          correct_source = <<~CORRECT
          def up
            migrate_async(ClazzName, "Bar", "Baz")
          end
          CORRECT

          expect(autocorrect_source(source)).to eq(correct_source)
        end
      end

      context 'BackgroundMigrationWorker.perform_in' do
        let(:source) do
          <<~SOURCE
            def up
              BackgroundMigrationWorker
                .perform_in(delay, ClazzName, "Bar", "Baz")
            end
          SOURCE
        end

        it 'adds an offence' do
          inspect_source(source)

          expect(cop.offenses.size).to eq(1)
        end

        it 'autocorrects to the right version' do
          correct_source = <<~CORRECT
            def up
              migrate_in(delay, ClazzName, "Bar", "Baz")
            end
          CORRECT

          expect(autocorrect_source(source)).to eq(correct_source)
        end
      end

      context 'BackgroundMigrationWorker.bulk_perform_async' do
        let(:source) do
          <<~SOURCE
            def up
              BackgroundMigrationWorker
                .bulk_perform_async(jobs)
            end
          SOURCE
        end

        it 'adds an offence' do
          inspect_source(source)

          expect(cop.offenses.size).to eq(1)
        end

        it 'autocorrects to the right version' do
          correct_source = <<~CORRECT
            def up
              bulk_migrate_async(jobs)
            end
          CORRECT

          expect(autocorrect_source(source)).to eq(correct_source)
        end
      end

      context 'BackgroundMigrationWorker.bulk_perform_in' do
        let(:source) do
          <<~SOURCE
            def up
              BackgroundMigrationWorker
                .bulk_perform_in(5.minutes, jobs)
            end
          SOURCE
        end

        it 'adds an offence' do
          inspect_source(source)

          expect(cop.offenses.size).to eq(1)
        end

        it 'autocorrects to the right version' do
          correct_source = <<~CORRECT
            def up
              bulk_migrate_in(5.minutes, jobs)
            end
          CORRECT

          expect(autocorrect_source(source)).to eq(correct_source)
        end
      end
    end
  end
end
