# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Dump::Postgres, feature_category: :backup_restore do
  let(:pg_database) { 'gitlabhq_test' }
  let(:pg_dump) { ::Gitlab::Backup::Cli::Utils::PgDump.new(database_name: pg_database) }
  let(:default_compression_cmd) { 'gzip -c -1' }

  subject(:postgres) { described_class.new }

  describe '#compress_cmd' do
    it 'returns default compression command' do
      expect(postgres.compress_cmd).to eq(default_compression_cmd)
    end
  end

  describe '#dump' do
    let(:pipes) { IO.pipe }
    let(:destination_dir) { Dir.mktmpdir }
    let(:dump_file_name) { File.join(destination_dir, 'output.gz') }

    before do
      allow(IO).to receive(:pipe).and_return(pipes)
    end

    after do
      FileUtils.remove_entry destination_dir
    end

    context 'with default compression method' do
      it 'creates a dump file' do
        postgres.dump(dump_file_name, pg_dump)

        expect(File.exist?(dump_file_name)).to eq(true)
      end

      it 'default compression command is used' do
        compressor_pid = spawn(default_compression_cmd, in: pipes[0], out: [dump_file_name, 'w', 0o600])

        expect(postgres).to receive(:spawn).with(
          default_compression_cmd,
          in: pipes.first,
          out: [dump_file_name, 'w', 0o600]).and_return(compressor_pid)

        postgres.dump(dump_file_name, pg_dump)

        expect(File.exist?(dump_file_name)).to eq(true)
      end
    end

    context 'when COMPRESS_CMD is set to tee' do
      let(:tee_pid) { spawn('tee', in: pipes[0], out: [dump_file_name, 'w', 0o600]) }

      before do
        stub_env('COMPRESS_CMD', 'tee')
      end

      it 'creates a dump file' do
        postgres.dump(dump_file_name, pg_dump)

        expect(File.exist?(dump_file_name)).to eq(true)
      end

      it 'passes through tee instead of gzip' do
        custom_compression_command = 'tee'
        compressor_pid = spawn(custom_compression_command, in: pipes[0], out: [dump_file_name, 'w', 0o600])

        expect(postgres).to receive(:spawn).with(
          custom_compression_command,
          in: pipes.first,
          out: [dump_file_name, 'w', 0o600]).and_return(compressor_pid)

        expect do
          postgres.dump(dump_file_name, pg_dump)
        end.to output(/Using custom COMPRESS_CMD 'tee'/).to_stdout

        expect(File.exist?(dump_file_name)).to eq(true)
      end
    end
  end
end
