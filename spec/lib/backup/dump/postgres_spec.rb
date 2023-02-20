# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Dump::Postgres, feature_category: :backup_restore do
  describe '#dump' do
    let(:pg_database) { 'gitlabhq_test' }
    let(:destination_dir) { Dir.mktmpdir }
    let(:db_file_name) { File.join(destination_dir, 'output.gz') }

    let(:pipes) { IO.pipe }
    let(:gzip_pid) { spawn('gzip -c -1', in: pipes[0], out: [db_file_name, 'w', 0o600]) }
    let(:pg_dump_pid) { Process.spawn('pg_dump', *args, pg_database, out: pipes[1]) }
    let(:args) { ['--help'] }

    subject { described_class.new }

    before do
      allow(IO).to receive(:pipe).and_return(pipes)
    end

    after do
      FileUtils.remove_entry destination_dir
    end

    it 'creates gzipped dump using supplied arguments' do
      expect(subject).to receive(:spawn).with('gzip -c -1', in: pipes.first,
                                                            out: [db_file_name, 'w', 0o600]).and_return(gzip_pid)
      expect(Process).to receive(:spawn).with('pg_dump', *args, pg_database, out: pipes[1]).and_return(pg_dump_pid)

      subject.dump(pg_database, db_file_name, args)

      expect(File.exist?(db_file_name)).to eq(true)
    end
  end
end
