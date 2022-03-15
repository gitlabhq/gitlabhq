# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Uploads do
  let(:progress) { StringIO.new }

  subject(:backup) { described_class.new(progress) }

  describe '#dump' do
    before do
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with('/var/uploads').and_return('/var/uploads')
      allow(File).to receive(:realpath).with('/var/uploads/..').and_return('/var')
      allow(Gitlab.config.uploads).to receive(:storage_path) { '/var' }
    end

    it 'excludes tmp from backup tar' do
      expect(backup).to receive(:tar).and_return('blabla-tar')
      expect(backup).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found --exclude=./tmp -C /var/uploads -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(backup).to receive(:pipeline_succeeded?).and_return(true)
      backup.dump('uploads.tar.gz')
    end
  end
end
