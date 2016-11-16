require 'spec_helper'

describe GeoRepositoryUpdateWorker do
  include RepoHelpers

  let(:user) { create :user }
  let(:project) { create :project }

  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev) { sample_commit.parent_id }
  let(:newrev) { sample_commit.id }
  let(:ref) { 'refs/heads/master' }

  let(:service) { execute_push_service(project, user, oldrev, newrev, ref) }
  let(:push_data) { service.push_data }
  let(:parsed_push_data) do
    {
      'type' => push_data[:object_kind],
      'before' => push_data[:before],
      'after' => push_data[:after],
      'ref' => push_data[:ref]
    }
  end

  let(:clone_url) { push_data[:project][:git_ssh_url] }
  let(:performed) { subject.perform(project.id, clone_url, parsed_push_data) }

  before do
    project.team << [user, :master]
    expect(Project).to receive(:find).at_least(:once).with(project.id) { project }
  end

  context 'when no repository' do
    before do
      allow(project.repository).to receive(:fetch_geo_mirror)
      allow(project).to receive(:repository_exists?) { false }
    end

    it 'creates a new repository' do
      expect(project).to receive(:create_repository)

      performed
    end

    it 'executes after_create hook' do
      expect(project.repository).to receive(:after_create)

      performed
    end
  end

  context 'when empty repository' do
    before do
      allow(project.repository).to receive(:fetch_geo_mirror)
      allow(project).to receive(:empty_repo?) { true }
    end

    it 'executes after_create hook' do
      expect(project.repository).to receive(:after_create).at_least(:once)

      performed
    end
  end

  context '#process_hooks' do
    before { allow(subject).to receive(:fetch_repository) }

    it 'calls if push_data is present' do
      expect(subject).to receive(:process_hooks)

      performed
    end

    context 'when no push_data is present' do
      let(:parsed_push_data) { nil }

      it 'skips process_hooks' do
        expect(subject).not_to receive(:process_hooks)

        performed
      end
    end
  end

  context '#process_push' do
    before { allow(subject).to receive(:fetch_repository) }

    it 'executes after_push_commit' do
      expect(project.repository).to receive(:after_push_commit).at_least(:once).with('master', newrev)

      performed
    end

    context 'when removing branch' do
      it 'executes after_remove_branch' do
        allow(subject).to receive(:push_remove_branch?) { true }
        expect(project.repository).to receive(:after_remove_branch)

        performed
      end
    end

    context 'when updating a new branch' do
      it 'executes after_create_branch' do
        allow(subject).to receive(:push_to_new_branch?) { true }
        expect(project.repository).to receive(:after_create_branch)

        performed
      end
    end
  end

  def execute_push_service(project, user, oldrev, newrev, ref)
    service = GitPushService.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
    service.execute
    service
  end
end
