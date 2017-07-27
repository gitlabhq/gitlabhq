require 'spec_helper'

describe Geo::ScheduleRepoUpdateService do
  include RepoHelpers

  let(:user) { create :user }
  let(:project) { create :project }

  let(:blankrev) { Gitlab::Git::BLANK_SHA }
  let(:oldrev) { sample_commit.parent_id }
  let(:newrev) { sample_commit.id }
  let(:ref) { 'refs/heads/master' }

  let(:service) { execute_push_service(project, user, oldrev, newrev, ref) }

  before do
    project.team << [user, :master]
  end

  subject { described_class.new(service.push_data) }

  context 'parsed push_data' do
    it 'includes required params' do
      expect(subject.push_data).to include('type', 'before', 'after', 'ref')
    end
  end

  context '#execute' do
    let(:push_data) { service.push_data }
    let(:args) do
      [
        project.id,
        push_data[:project][:git_ssh_url],
        {
          'type' => push_data[:object_kind],
          'before' => push_data[:before],
          'after' => push_data[:newref],
          'ref' => push_data[:ref]
        }
      ]
    end

    it 'schedule update service' do
      expect(GeoRepositoryUpdateWorker).to receive(:perform_async).with(*args)

      subject.execute
    end
  end

  def execute_push_service(project, user, oldrev, newrev, ref)
    service = GitPushService.new(project, user, oldrev: oldrev, newrev: newrev, ref: ref)
    service.execute
    service
  end
end
