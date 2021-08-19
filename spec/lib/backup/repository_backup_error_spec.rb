# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::RepositoryBackupError do
  let_it_be(:snippet) { create(:snippet, content: 'foo', file_name: 'foo') }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:wiki) { ProjectWiki.new(project, nil ) }

  let(:backup_repos_path) { '/tmp/backup/repositories' }

  shared_examples 'includes backup path' do
    it { is_expected.to respond_to :container }
    it { is_expected.to respond_to :backup_repos_path }

    it 'expects exception message to include repo backup path location' do
      expect(subject.message).to include("#{subject.backup_repos_path}")
    end

    it 'expects exception message to include container being back-up' do
      expect(subject.message).to include("#{subject.container.disk_path}")
    end
  end

  context 'with snippet repository' do
    subject { described_class.new(snippet, backup_repos_path) }

    it_behaves_like 'includes backup path'
  end

  context 'with project repository' do
    subject { described_class.new(project, backup_repos_path) }

    it_behaves_like 'includes backup path'
  end

  context 'with wiki repository' do
    subject { described_class.new(wiki, backup_repos_path) }

    it_behaves_like 'includes backup path'
  end
end
