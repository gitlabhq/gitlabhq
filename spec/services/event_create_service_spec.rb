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
    let(:project) { create(:empty_project) }
    let(:user) { create(:user) }

    it 'creates a new event' do
      expect { service.push(project, user, {}) }.to change { Event.count }
    end

    it 'updates user last activity' do
      expect { service.push(project, user, {}) }.to change { user_activity(user) }
    end
  end

  describe 'Project' do
    let(:user) { create :user }
    let(:project) { create(:empty_project) }

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
