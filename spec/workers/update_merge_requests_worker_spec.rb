require 'spec_helper'

describe UpdateMergeRequestsWorker do
  include RepoHelpers

  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new }

  describe '#perform' do
    let(:oldrev) { "123456" }
    let(:newrev) { "789012" }
    let(:ref)    { "refs/heads/test" }

    def perform
      subject.perform(project.id, user.id, oldrev, newrev, ref)
    end

    it 'executes MergeRequests::RefreshService with expected values' do
      expect(MergeRequests::RefreshService).to receive(:new).with(project, user).and_call_original
      expect_any_instance_of(MergeRequests::RefreshService).to receive(:execute).with(oldrev, newrev, ref)

      perform
    end

    it 'executes SystemHooksService with expected values' do
      push_data = double('push_data')
      expect(Gitlab::DataBuilder::Push).to receive(:build).with(project, user, oldrev, newrev, ref, []).and_return(push_data)

      system_hook_service = double('system_hook_service')
      expect(SystemHooksService).to receive(:new).and_return(system_hook_service)
      expect(system_hook_service).to receive(:execute_hooks).with(push_data, :push_hooks)

      perform
    end
  end
end
