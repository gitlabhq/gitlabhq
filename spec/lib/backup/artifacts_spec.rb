# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Artifacts do
  let(:progress) { StringIO.new }

  subject(:backup) { described_class.new(progress) }

  describe '#initialize' do
    it 'uses the correct upload dir' do
      Dir.mktmpdir do |tmpdir|
        allow(JobArtifactUploader).to receive(:root) { "#{tmpdir}" }

        expect(backup.app_files_dir).to eq("#{tmpdir}")
      end
    end
  end

  describe '#dump' do
    before do
      allow(File).to receive(:realpath).with('/var/gitlab-artifacts').and_return('/var/gitlab-artifacts')
      allow(File).to receive(:realpath).with('/var/gitlab-artifacts/..').and_return('/var')
      allow(JobArtifactUploader).to receive(:root) { '/var/gitlab-artifacts' }
    end

    it 'uses the correct artifact dir' do
      expect(backup.app_files_dir).to eq('/var/gitlab-artifacts')
    end

    it 'excludes tmp from backup tar' do
      expect(backup).to receive(:tar).and_return('blabla-tar')
      expect(backup).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found --exclude=./tmp -C /var/gitlab-artifacts -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(backup).to receive(:pipeline_succeeded?).and_return(true)
      backup.dump
    end
  end
end
