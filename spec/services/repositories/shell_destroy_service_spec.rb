# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::ShellDestroyService do
  let_it_be(:user) { create(:user) }

  let!(:project) { create(:project, :repository, namespace: user.namespace) }
  let(:path) { project.repository.disk_path }
  let(:remove_path) { "#{path}+#{project.id}#{described_class::DELETED_FLAG}" }

  it 'returns success if the repository is nil' do
    expect(GitlabShellWorker).not_to receive(:perform_in)

    result = described_class.new(nil).execute

    expect(result[:status]).to eq :success
  end

  it 'schedules the repository deletion' do
    expect(GitlabShellWorker).to receive(:perform_in)
      .with(described_class::REPO_REMOVAL_DELAY, :remove_repository, project.repository_storage, remove_path)

    described_class.new(project.repository).execute
  end
end
