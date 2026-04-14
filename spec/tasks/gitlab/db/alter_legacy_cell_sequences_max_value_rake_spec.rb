# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:alter_legacy_cell_sequences_max_value', :silence_stdout, feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/alter_legacy_cell_sequences_max_value'
  end

  let(:maxval) { 999_999_999_999 }
  let(:alter_legacy_cell_sequences_max_value) do
    instance_double(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
  end

  describe 'gitlab:db:alter_legacy_cell_sequences_max_value' do
    subject(:run_rake) { run_rake_task('gitlab:db:alter_legacy_cell_sequences_max_value', maxval) }

    shared_examples 'alters legacy cell sequences max value' do
      it 'executes AlterLegacyCellSequencesMaxValue' do
        Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
          expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
            .to receive(:new)
            .with(maxval, connection, sequence_names: nil, skip_trigger_install: false)
            .and_return(alter_legacy_cell_sequences_max_value)

          expect(alter_legacy_cell_sequences_max_value).to receive(:execute)
        end

        run_rake
      end
    end

    shared_examples 'does not alter legacy cell sequences max value' do
      it 'does not execute AlterLegacyCellSequencesMaxValue' do
        expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue).not_to receive(:new)

        run_rake
      end
    end

    context 'when run in non Gitlab.com/dev/test environment' do
      before do
        allow(Gitlab).to receive_messages(com_except_jh?: false, dev_or_test_env?: false)
        stub_config(cell: { enabled: true, database: { skip_sequence_alteration: false } })
      end

      it_behaves_like 'does not alter legacy cell sequences max value'
    end

    context 'when skipping database sequence alteration' do
      before do
        allow(Gitlab).to receive_messages(com_except_jh?: true, dev_or_test_env?: true)
        stub_config(cell: { enabled: true, database: { skip_sequence_alteration: true } })
      end

      it_behaves_like 'does not alter legacy cell sequences max value'
    end

    context 'when run in Gitlab.com but not jh instance' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
        stub_config(cell: { enabled: true, database: { skip_sequence_alteration: false } })
      end

      it_behaves_like 'alters legacy cell sequences max value'

      context 'when maxval is nil' do
        let(:maxval) { nil }

        it 'passes nil value to AlterLegacyCellSequencesMaxValue' do
          Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
            expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
              .to receive(:new)
              .with(nil, connection, sequence_names: nil, skip_trigger_install: false)
              .and_return(alter_legacy_cell_sequences_max_value)

            expect(alter_legacy_cell_sequences_max_value).to receive(:execute)
          end

          run_rake
        end
      end
    end

    context 'when run in dev or test env' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
        stub_config(cell: { enabled: true, database: { skip_sequence_alteration: false } })
      end

      it_behaves_like 'alters legacy cell sequences max value'

      context 'with SEQUENCE_NAMES env var' do
        using RSpec::Parameterized::TableSyntax

        where(:env_value, :expected_sequence_names) do
          'projects_id_seq, namespaces_id_seq' | %w[projects_id_seq namespaces_id_seq]
          'projects_id_seq'                    | %w[projects_id_seq]
          'projects_id_seq,,namespaces_id_seq' | %w[projects_id_seq namespaces_id_seq]
          ''                                   | nil
          nil                                  | nil
        end

        with_them do
          before do
            stub_env('SEQUENCE_NAMES', env_value)
          end

          it 'passes parsed sequence names to AlterLegacyCellSequencesMaxValue' do
            Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
              expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
                .to receive(:new)
                .with(maxval, connection, sequence_names: expected_sequence_names, skip_trigger_install: false)
                .and_return(alter_legacy_cell_sequences_max_value)

              expect(alter_legacy_cell_sequences_max_value).to receive(:execute)
            end

            run_rake
          end
        end
      end

      context 'with SKIP_SEQUENCE_TRIGGER_INSTALL env var' do
        before do
          stub_env('SKIP_SEQUENCE_TRIGGER_INSTALL', 'true')
        end

        it 'passes skip_trigger_install as true to AlterLegacyCellSequencesMaxValue' do
          Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
            expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
              .to receive(:new)
              .with(maxval, connection, sequence_names: nil, skip_trigger_install: true)
              .and_return(alter_legacy_cell_sequences_max_value)

            expect(alter_legacy_cell_sequences_max_value).to receive(:execute)
          end

          run_rake
        end
      end
    end
  end

  describe 'gitlab:db:rollback_alter_legacy_cell_sequences_max_value' do
    subject(:run_rake) { run_rake_task('gitlab:db:rollback_alter_legacy_cell_sequences_max_value') }

    let(:default_max) { Gitlab::Database::AlterLegacyCellSequencesMaxValue::DEFAULT_MAX_VALUE }

    shared_examples 'rolls back legacy cell sequences max value' do
      it 'executes rollback on AlterLegacyCellSequencesMaxValue' do
        Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
          expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
            .to receive(:new)
            .with(default_max, connection, sequence_names: nil)
            .and_return(alter_legacy_cell_sequences_max_value)

          expect(alter_legacy_cell_sequences_max_value).to receive(:rollback)
        end

        run_rake
      end
    end

    shared_examples 'does not roll back legacy cell sequences max value' do
      it 'does not execute AlterLegacyCellSequencesMaxValue' do
        expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue).not_to receive(:new)

        run_rake
      end
    end

    context 'when run in non Gitlab.com/dev/test environment' do
      before do
        allow(Gitlab).to receive_messages(com_except_jh?: false, dev_or_test_env?: false)
      end

      it_behaves_like 'does not roll back legacy cell sequences max value'
    end

    context 'when run in Gitlab.com but not jh instance' do
      before do
        allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      end

      it_behaves_like 'rolls back legacy cell sequences max value'
    end

    context 'when run in dev or test env' do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(true)
      end

      it_behaves_like 'rolls back legacy cell sequences max value'

      context 'with SEQUENCE_NAMES env var' do
        using RSpec::Parameterized::TableSyntax

        where(:env_value, :expected_sequence_names) do
          'projects_id_seq, namespaces_id_seq' | %w[projects_id_seq namespaces_id_seq]
          'projects_id_seq'                    | %w[projects_id_seq]
          'projects_id_seq,,namespaces_id_seq' | %w[projects_id_seq namespaces_id_seq]
          ''                                   | nil
          nil                                  | nil
        end

        with_them do
          before do
            stub_env('SEQUENCE_NAMES', env_value)
          end

          it 'passes parsed sequence names to AlterLegacyCellSequencesMaxValue' do
            Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
              expect(Gitlab::Database::AlterLegacyCellSequencesMaxValue)
                .to receive(:new)
                .with(default_max, connection, sequence_names: expected_sequence_names)
                .and_return(alter_legacy_cell_sequences_max_value)

              expect(alter_legacy_cell_sequences_max_value).to receive(:rollback)
            end

            run_rake
          end
        end
      end
    end
  end
end
