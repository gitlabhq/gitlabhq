# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::DestroyRollbackService do
  let_it_be(:user) { create(:user) }

  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:repository) { project.repository }
  let(:path) { repository.disk_path }
  let(:remove_path) { "#{path}+#{project.id}#{described_class::DELETED_FLAG}" }

  subject { described_class.new(repository).execute }

  before do
    # Dont run sidekiq to check if renamed repository exists
    Sidekiq::Testing.fake! { destroy_project(project, user) }
  end

  it 'moves the repository from the +deleted folder' do
    expect(project.gitlab_shell.repository_exists?(project.repository_storage, remove_path + '.git')).to be_truthy
    expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_falsey

    subject

    expect(project.gitlab_shell.repository_exists?(project.repository_storage, remove_path + '.git')).to be_falsey
    expect(project.gitlab_shell.repository_exists?(project.repository_storage, path + '.git')).to be_truthy
  end

  it 'logs the successful action' do
    expect(Gitlab::AppLogger).to receive(:info)

    subject
  end

  it 'flushes the repository cache' do
    expect(repository).to receive(:before_delete)

    subject
  end

  it 'returns success and does not perform any action if repository path does not exist' do
    expect(repository).to receive(:disk_path).and_return('foo')
    expect(repository).not_to receive(:before_delete)

    result = subject

    expect(result[:status]).to eq :success
  end

  context 'when move operation cannot be performed' do
    let(:service) { described_class.new(repository) }

    before do
      allow(service).to receive(:mv_repository).and_return(false)
    end

    it 'returns error' do
      result = service.execute

      expect(result[:status]).to eq :error
    end

    it 'logs the error' do
      expect(Gitlab::AppLogger).to receive(:error)

      service.execute
    end
  end

  def destroy_project(project, user)
    Projects::DestroyService.new(project, user, {}).execute
  end
end
