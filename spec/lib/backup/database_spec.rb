# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Database, feature_category: :backup_restore do
  let(:progress) { StringIO.new }
  let(:output) { progress.string }
  let(:one_db_configured?) { Gitlab::Database.database_base_models.one? }
  let(:database_models_for_backup) { Gitlab::Database.database_base_models_with_gitlab_shared }

  before(:all) do
    Rake::Task.define_task(:environment)
    Rake.application.rake_require 'active_record/railties/databases'
    Rake.application.rake_require 'tasks/gitlab/backup'
    Rake.application.rake_require 'tasks/gitlab/shell'
    Rake.application.rake_require 'tasks/gitlab/db'
    Rake.application.rake_require 'tasks/cache'
  end

  describe '#dump', :delete do
    let(:backup_id) { 'some_id' }
    let(:force) { true }

    subject { described_class.new(progress, force: force) }

    before do
      database_models_for_backup.each do |database_name, base_model|
        base_model.connection.rollback_transaction unless base_model.connection.open_transactions.zero?
      end
    end

    it 'creates gzipped database dumps' do
      Dir.mktmpdir do |dir|
        subject.dump(dir, backup_id)

        database_models_for_backup.each_key do |database_name|
          filename = database_name == 'main' ? 'database.sql.gz' : "#{database_name}_database.sql.gz"
          expect(File.exist?(File.join(dir, filename))).to eq(true)
        end
      end
    end

    it 'uses snapshots' do
      Dir.mktmpdir do |dir|
        base_model = Gitlab::Database.database_base_models['main']
        expect(base_model.connection).to receive(:begin_transaction).with(
          isolation: :repeatable_read
        ).and_call_original
        expect(base_model.connection).to receive(:execute).with(
          "SELECT pg_export_snapshot() as snapshot_id;"
        ).and_call_original
        expect(base_model.connection).to receive(:rollback_transaction).and_call_original

        subject.dump(dir, backup_id)
      end
    end

    describe 'pg_dump arguments' do
      let(:snapshot_id) { 'fake_id' }
      let(:pg_args) do
        [
          '--clean',
          '--if-exists',
          "--snapshot=#{snapshot_id}"
        ]
      end

      let(:dumper) { double }
      let(:destination_dir) { 'tmp' }

      before do
        allow(Backup::Dump::Postgres).to receive(:new).and_return(dumper)
        allow(dumper).to receive(:dump).with(any_args).and_return(true)

        database_models_for_backup.each do |database_name, base_model|
          allow(base_model.connection).to receive(:execute).with(
            "SELECT pg_export_snapshot() as snapshot_id;"
          ).and_return(['snapshot_id' => snapshot_id])
        end
      end

      it 'calls Backup::Dump::Postgres with correct pg_dump arguments' do
        expect(dumper).to receive(:dump).with(anything, anything, pg_args)

        subject.dump(destination_dir, backup_id)
      end

      context 'when a PostgreSQL schema is used' do
        let(:schema) { 'gitlab' }
        let(:additional_args) do
          pg_args + ['-n', schema] + Gitlab::Database::EXTRA_SCHEMAS.flat_map do |schema|
            ['-n', schema.to_s]
          end
        end

        before do
          allow(Gitlab.config.backup).to receive(:pg_schema).and_return(schema)
        end

        it 'calls Backup::Dump::Postgres with correct pg_dump arguments' do
          expect(dumper).to receive(:dump).with(anything, anything, additional_args)

          subject.dump(destination_dir, backup_id)
        end
      end
    end
  end

  describe '#restore' do
    let(:cmd) { %W[#{Gem.ruby} -e $stdout.puts(1)] }
    let(:backup_dir) { Rails.root.join("spec/fixtures/") }
    let(:force) { true }
    let(:rake_task) { instance_double(Rake::Task, invoke: true) }

    subject { described_class.new(progress, force: force) }

    before do
      allow(Rake::Task).to receive(:[]).with(any_args).and_return(rake_task)

      allow(subject).to receive(:pg_restore_cmd).and_return(cmd)
    end

    context 'when not forced' do
      let(:force) { false }

      it 'warns the user and waits' do
        expect(subject).to receive(:sleep)

        if one_db_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        subject.restore(backup_dir)

        expect(output).to include('Removing all tables. Press `Ctrl-C` within 5 seconds to abort')
      end

      it 'has a pre restore warning' do
        expect(subject.pre_restore_warning).not_to be_nil
      end
    end

    context 'with an empty .gz file' do
      it 'returns successfully' do
        if one_db_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        subject.restore(backup_dir)

        expect(output).to include("Restoring PostgreSQL database")
        expect(output).to include("[DONE]")
        expect(output).not_to include("ERRORS")
      end
    end

    context 'with a corrupted .gz file' do
      before do
        allow(subject).to receive(:file_name).and_return("#{backup_dir}big-image.png")
      end

      it 'raises a backup error' do
        if one_db_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        expect { subject.restore(backup_dir) }.to raise_error(Backup::Error)
      end
    end

    context 'when the restore command prints errors' do
      let(:visible_error) { "This is a test error\n" }
      let(:noise) { "must be owner of extension pg_trgm\nWARNING:  no privileges could be revoked for public\n" }
      let(:cmd) { %W[#{Gem.ruby} -e $stderr.write("#{noise}#{visible_error}")] }

      it 'filters out noise from errors and has a post restore warning' do
        if one_db_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        subject.restore(backup_dir)

        expect(output).to include("ERRORS")
        expect(output).not_to include(noise)
        expect(output).to include(visible_error)
        expect(subject.post_restore_warning).not_to be_nil
      end
    end

    context 'with PostgreSQL settings defined in the environment' do
      let(:cmd) { %W[#{Gem.ruby} -e] + ["$stderr.puts ENV.to_h.select { |k, _| k.start_with?('PG') }"] }
      let(:config) { YAML.load_file(File.join(Rails.root, 'config', 'database.yml'))['test'] }

      before do
        stub_const 'ENV', ENV.to_h.merge({
          'GITLAB_BACKUP_PGHOST' => 'test.example.com',
          'PGPASSWORD' => 'donotchange'
        })
      end

      it 'overrides default config values' do
        if one_db_configured?
          expect(Rake::Task['gitlab:db:drop_tables']).to receive(:invoke)
        else
          expect(Rake::Task['gitlab:db:drop_tables:main']).to receive(:invoke)
        end

        subject.restore(backup_dir)

        expect(output).to include(%("PGHOST"=>"test.example.com"))
        expect(output).to include(%("PGPASSWORD"=>"donotchange"))
        expect(output).to include(%("PGPORT"=>"#{config['port']}")) if config['port']
        expect(output).to include(%("PGUSER"=>"#{config['username']}")) if config['username']
      end
    end

    context 'when the source file is missing' do
      context 'for main database' do
        before do
          allow(File).to receive(:exist?).and_call_original
          allow(File).to receive(:exist?).with("#{backup_dir}database.sql.gz").and_return(false)
          allow(File).to receive(:exist?).with("#{backup_dir}ci_database.sql.gz").and_return(false)
        end

        it 'raises an error about missing source file' do
          if one_db_configured?
            expect(Rake::Task['gitlab:db:drop_tables']).not_to receive(:invoke)
          else
            expect(Rake::Task['gitlab:db:drop_tables:main']).not_to receive(:invoke)
          end

          expect do
            subject.restore('db')
          end.to raise_error(Backup::Error, /Source database file does not exist/)
        end
      end

      context 'for ci database' do
        it 'ci database tolerates missing source file' do
          expect { subject.restore(backup_dir) }.not_to raise_error
        end
      end
    end
  end
end
