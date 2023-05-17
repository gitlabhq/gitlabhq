# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::DestroyService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }

  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:repository) { project.repository }
  let(:path) { repository.disk_path }

  subject { described_class.new(repository).execute }

  it 'removes the repository' do
    expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_truthy

    subject

    # Because the removal happens inside a run_after_commit callback we need to
    # trigger the callback
    project.touch

    expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_falsey
  end

  context 'on a read-only instance' do
    before do
      allow(Gitlab::Database).to receive(:read_only?).and_return(true)
    end

    it 'schedules the repository deletion' do
      expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_truthy

      subject

      expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_falsey
    end
  end

  it 'flushes the repository cache' do
    expect(repository).to receive(:before_delete)

    subject
  end

  it 'does not perform any action if repository path does not exist and returns success' do
    expect(repository).to receive(:disk_path).and_return('foo')
    expect(repository).not_to receive(:before_delete)

    expect(subject[:status]).to eq :success
  end

  it 'gracefully handles exception if the repository does not exist on disk' do
    expect(repository).to receive(:before_delete).and_raise(Gitlab::Git::Repository::NoRepository)
    expect(subject[:status]).to eq :success
  end

  context 'with a project wiki repository' do
    let(:project) { create(:project, :wiki_repo) }
    let(:repository) { project.wiki.repository }

    it 'schedules the repository deletion' do
      expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_truthy

      subject

      # Because the removal happens inside a run_after_commit callback we need to
      # trigger the callback
      project.touch

      expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_falsey
    end
  end
end
