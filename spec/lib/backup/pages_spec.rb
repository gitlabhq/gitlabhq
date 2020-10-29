# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Pages do
  let(:progress) { StringIO.new }

  subject { described_class.new(progress) }

  before do
    allow(File).to receive(:realpath).with("/var/gitlab-pages").and_return("/var/gitlab-pages")
    allow(File).to receive(:realpath).with("/var/gitlab-pages/..").and_return("/var")
  end

  describe '#dump' do
    it 'uses the correct pages dir' do
      allow(Gitlab.config.pages).to receive(:path) { '/var/gitlab-pages' }

      expect(subject.app_files_dir).to eq('/var/gitlab-pages')
    end

    it 'excludes tmp from backup tar' do
      allow(Gitlab.config.pages).to receive(:path) { '/var/gitlab-pages' }

      expect(subject).to receive(:tar).and_return('blabla-tar')
      expect(subject).to receive(:run_pipeline!).with([%w(blabla-tar --exclude=lost+found --exclude=./@pages.tmp -C /var/gitlab-pages -cf - .), 'gzip -c -1'], any_args).and_return([[true, true], ''])
      expect(subject).to receive(:pipeline_succeeded?).and_return(true)
      subject.dump
    end
  end
end
