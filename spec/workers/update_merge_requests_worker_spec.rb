require 'spec_helper'

describe UpdateMergeRequestsWorker do
  include RepoHelpers

  let(:project) { create(:project, :repository) }
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
  end
end
