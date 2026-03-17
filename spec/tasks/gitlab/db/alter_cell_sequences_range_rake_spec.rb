# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db:alter_cell_sequences_range', :silence_stdout, feature_category: :database do
  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/alter_cell_sequences_range'
  end

  let(:minval) { 100 }
  let(:maxval) { 200 }
  let(:alter_cell_sequence_range) { instance_double(Gitlab::Database::AlterCellSequencesRange) }

  subject(:run_rake) { run_rake_task('gitlab:db:alter_cell_sequences_range', minval, maxval) }

  shared_examples 'alters cell sequences range' do
    it 'executes AlterCellSequencesRange' do
      Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
        expect(Gitlab::Database::AlterCellSequencesRange)
          .to receive(:new).with(minval, maxval, connection, sequence_names: nil).and_return(alter_cell_sequence_range)

        expect(alter_cell_sequence_range).to receive(:execute)
      end

      run_rake
    end
  end

  shared_examples 'does not alter cell sequences range' do
    it 'does not executes AlterCellSequencesRange' do
      expect(Gitlab::Database::AlterCellSequencesRange).not_to receive(:new)

      run_rake
    end
  end

  context 'when run in non Gitlab.com/dev/test environment' do
    before do
      allow(Gitlab).to receive_messages(com_except_jh?: false, dev_or_test_env?: false)
      stub_config(cell: { enabled: true, database: { skip_sequence_alteration: false } })
    end

    it_behaves_like 'does not alter cell sequences range'
  end

  # This setting (skip_sequence_alteration) is meant for the Legacy cell
  # All additional Cells are still considered .com
  context 'when skipping database sequence alteration' do
    before do
      allow(Gitlab).to receive_messages(com_except_jh?: true, dev_or_test_env?: true)
      stub_config(cell: { enabled: true, database: { skip_sequence_alteration: true } })
    end

    it_behaves_like 'does not alter cell sequences range'
  end

  context 'when run in Gitlab.com but not jh instance' do
    before do
      allow(Gitlab).to receive(:com_except_jh?).and_return(true)
      stub_config(cell: { enabled: true, database: { skip_sequence_alteration: false } })
    end

    it_behaves_like 'alters cell sequences range'

    context 'when minval and maxval are nil' do
      let(:minval) { nil }
      let(:maxval) { nil }

      it 'passes nil values to AlterCellSequencesRange' do
        Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
          expect(Gitlab::Database::AlterCellSequencesRange)
            .to receive(:new).with(nil, nil, connection, sequence_names: nil).and_return(alter_cell_sequence_range)

          expect(alter_cell_sequence_range).to receive(:execute)
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

    it_behaves_like 'alters cell sequences range'

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

        it 'passes parsed sequence names to AlterCellSequencesRange' do
          Gitlab::Database::EachDatabase.each_connection do |connection, _database_name|
            expect(Gitlab::Database::AlterCellSequencesRange)
              .to receive(:new)
              .with(minval, maxval, connection, sequence_names: expected_sequence_names)
              .and_return(alter_cell_sequence_range)

            expect(alter_cell_sequence_range).to receive(:execute)
          end

          run_rake
        end
      end
    end
  end
end
