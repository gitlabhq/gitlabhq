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

    context 'when slow' do
      before do
        stub_const("UpdateMergeRequestsWorker::LOG_TIME_THRESHOLD", -1)
      end

      it 'logs debug info' do
        expect(Rails.logger).to receive(:info).with(a_string_matching(/\AUpdateMergeRequestsWorker#perform.*project_id=#{project.id},user_id=#{user.id},oldrev=#{oldrev},newrev=#{newrev},ref=#{ref}/))

        perform
      end
    end
  end
end
