# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Lfs do
  let(:progress) { StringIO.new }

  subject(:backup) { described_class.new(progress) }

  describe '#dump' do
    before do
      allow(File).to receive(:realpath).and_call_original
      allow(File).to receive(:realpath).with('/var/lfs-objects').and_return('/var/lfs-objects')
      allow(File).to receive(:realpath).with('/var/lfs-objects/..').and_return('/var')
      allow(Settings.lfs).to receive(:storage_path).and_return('/var/lfs-objects')
    end

    it 'uses the correct lfs dir in tar command', :aggregate_failures do
      expect(backup).to receive(:tar).and_return('blabla-tar')
      expect(backup).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found -C /var/lfs-objects -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(backup).to receive(:pipeline_succeeded?).and_return(true)

      backup.dump('lfs.tar.gz')
    end
  end
end
