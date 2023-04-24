# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/migration/schedule_async'

RSpec.describe RuboCop::Cop::Migration::ScheduleAsync do
  let(:source) do
    <<~SOURCE
      def up
        BackgroundMigrationWorker.perform_async(ClazzName, "Bar", "Baz")
      end
    SOURCE
  end

  shared_examples 'a disabled cop' do
    it 'does not register any offenses' do
      expect_no_offenses(source)
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
        it 'adds an offense when calling `BackgroundMigrationWorker.peform_async`' do
          expect_offense(<<~RUBY)
            def up
              BackgroundMigrationWorker.perform_async(ClazzName, "Bar", "Baz")
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
            end
          RUBY
        end
      end

      context 'CiDatabaseWorker.perform_async' do
        it 'adds an offense when calling `CiDatabaseWorker.peform_async`' do
          expect_offense(<<~RUBY)
            def up
              CiDatabaseWorker.perform_async(ClazzName, "Bar", "Baz")
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
            end
          RUBY
        end
      end

      context 'BackgroundMigrationWorker.perform_in' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              BackgroundMigrationWorker
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
                .perform_in(delay, ClazzName, "Bar", "Baz")
            end
          RUBY
        end
      end

      context 'CiDatabaseWorker.perform_in' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              CiDatabaseWorker
              ^^^^^^^^^^^^^^^^ Don't call [...]
                .perform_in(delay, ClazzName, "Bar", "Baz")
            end
          RUBY
        end
      end

      context 'BackgroundMigrationWorker.bulk_perform_async' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              BackgroundMigrationWorker
              ^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
                .bulk_perform_async(jobs)
            end
          RUBY
        end
      end

      context 'CiDatabaseWorker.bulk_perform_async' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              BackgroundMigration::CiDatabaseWorker
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
                .bulk_perform_async(jobs)
            end
          RUBY
        end
      end

      context 'BackgroundMigrationWorker.bulk_perform_in' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              ::BackgroundMigrationWorker
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
                .bulk_perform_in(5.minutes, jobs)
            end
          RUBY
        end
      end

      context 'CiDatabaseWorker.bulk_perform_in' do
        it 'adds an offense' do
          expect_offense(<<~RUBY)
            def up
              ::BackgroundMigration::CiDatabaseWorker
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Don't call [...]
                .bulk_perform_in(5.minutes, jobs)
            end
          RUBY
        end
      end
    end
  end
end
