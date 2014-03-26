require 'spec_helper'

describe EventCreateService do
  let(:service) { EventCreateService.new }

  describe 'Issues' do
    describe :open_issue do
      let(:issue) { create(:issue) }

      it { service.open_issue(issue, issue.author).should be_true }

      it "should create new event" do
        expect { service.open_issue(issue, issue.author) }.to change { Event.count }
      end
    end

    describe :close_issue do
      let(:issue) { create(:issue) }

      it { service.close_issue(issue, issue.author).should be_true }

      it "should create new event" do
        expect { service.close_issue(issue, issue.author) }.to change { Event.count }
      end
    end

    describe :reopen_issue do
      let(:issue) { create(:issue) }

      it { service.reopen_issue(issue, issue.author).should be_true }

      it "should create new event" do
        expect { service.reopen_issue(issue, issue.author) }.to change { Event.count }
      end
    end
  end

  describe 'Merge Requests' do
    describe :open_mr do
      let(:merge_request) { create(:merge_request) }

      it { service.open_mr(merge_request, merge_request.author).should be_true }

      it "should create new event" do
        expect { service.open_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe :close_mr do
      let(:merge_request) { create(:merge_request) }

      it { service.close_mr(merge_request, merge_request.author).should be_true }

      it "should create new event" do
        expect { service.close_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe :merge_mr do
      let(:merge_request) { create(:merge_request) }

      it { service.merge_mr(merge_request, merge_request.author).should be_true }

      it "should create new event" do
        expect { service.merge_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe :reopen_mr do
      let(:merge_request) { create(:merge_request) }

      it { service.reopen_mr(merge_request, merge_request.author).should be_true }

      it "should create new event" do
        expect { service.reopen_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end
  end

  describe 'Milestone' do
    let(:user) { create :user }

    describe :open_milestone do
      let(:milestone) { create(:milestone) }

      it { service.open_milestone(milestone, user).should be_true }

      it "should create new event" do
        expect { service.open_milestone(milestone, user) }.to change { Event.count }
      end
    end

    describe :close_mr do
      let(:milestone) { create(:milestone) }

      it { service.close_milestone(milestone, user).should be_true }

      it "should create new event" do
        expect { service.close_milestone(milestone, user) }.to change { Event.count }
      end
    end
  end
end
