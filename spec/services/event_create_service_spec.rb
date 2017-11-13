require 'spec_helper'

describe EventCreateService do
  include UserActivitiesHelpers

  let(:service) { described_class.new }

  describe 'Issues' do
    describe '#open_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.open_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.open_issue(issue, issue.author) }.to change { Event.count }
      end
    end

    describe '#close_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.close_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.close_issue(issue, issue.author) }.to change { Event.count }
      end
    end

    describe '#reopen_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.reopen_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.reopen_issue(issue, issue.author) }.to change { Event.count }
      end
    end
  end

  describe 'Merge Requests' do
    describe '#open_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.open_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.open_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe '#close_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.close_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.close_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe '#merge_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.merge_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.merge_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe '#reopen_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.reopen_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.reopen_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end
  end

  describe 'Milestone' do
    let(:user) { create :user }

    describe '#open_milestone' do
      let(:milestone) { create(:milestone) }

      it { expect(service.open_milestone(milestone, user)).to be_truthy }

      it "creates new event" do
        expect { service.open_milestone(milestone, user) }.to change { Event.count }
      end
    end

    describe '#close_mr' do
      let(:milestone) { create(:milestone) }

      it { expect(service.close_milestone(milestone, user)).to be_truthy }

      it "creates new event" do
        expect { service.close_milestone(milestone, user) }.to change { Event.count }
      end
    end

    describe '#destroy_mr' do
      let(:milestone) { create(:milestone) }

      it { expect(service.destroy_milestone(milestone, user)).to be_truthy }

      it "creates new event" do
        expect { service.destroy_milestone(milestone, user) }.to change { Event.count }
      end
    end
  end

  describe '#push', :clean_gitlab_redis_shared_state do
    let(:project) { create(:project) }
    let(:user) { create(:user) }

    let(:push_data) do
      {
        commits: [
          {
            id: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
            message: 'This is a commit'
          }
        ],
        before: '0000000000000000000000000000000000000000',
        after: '1cf19a015df3523caf0a1f9d40c98a267d6a2fc2',
        total_commits_count: 1,
        ref: 'refs/heads/my-branch'
      }
    end

    it 'creates a new event' do
      expect { service.push(project, user, push_data) }.to change { Event.count }
    end

    it 'creates the push event payload' do
      expect(PushEventPayloadService).to receive(:new)
        .with(an_instance_of(PushEvent), push_data)
        .and_call_original

      service.push(project, user, push_data)
    end

    it 'updates user last activity' do
      expect { service.push(project, user, push_data) }
        .to change { user_activity(user) }
    end

    it 'caches the last push event for the user' do
      expect_any_instance_of(Users::LastPushEventService)
        .to receive(:cache_last_push_event)
        .with(an_instance_of(PushEvent))

      service.push(project, user, push_data)
    end

    it 'does not create any event data when an error is raised' do
      payload_service = double(:service)

      allow(payload_service).to receive(:execute)
        .and_raise(RuntimeError)

      allow(PushEventPayloadService).to receive(:new)
        .and_return(payload_service)

      expect { service.push(project, user, push_data) }
        .to raise_error(RuntimeError)

      expect(Event.count).to eq(0)
      expect(PushEventPayload.count).to eq(0)
    end
  end

  describe 'Project' do
    let(:user) { create :user }
    let(:project) { create(:project) }

    describe '#join_project' do
      subject { service.join_project(project, user) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { Event.count }.from(0).to(1) }
    end

    describe '#expired_leave_project' do
      subject { service.expired_leave_project(project, user) }

      it { is_expected.to be_truthy }
      it { expect { subject }.to change { Event.count }.from(0).to(1) }
    end
  end
end
