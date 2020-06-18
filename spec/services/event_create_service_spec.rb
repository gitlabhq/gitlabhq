# frozen_string_literal: true

require 'spec_helper'

describe EventCreateService do
  let(:service) { described_class.new }

  let_it_be(:user, reload: true) { create :user }
  let_it_be(:project) { create(:project) }

  describe 'Issues' do
    describe '#open_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.open_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.open_issue(issue, issue.author) }.to change { Event.count }
        expect { service.open_issue(issue, issue.author) }.to change { ResourceStateEvent.count }
      end
    end

    describe '#close_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.close_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.close_issue(issue, issue.author) }.to change { Event.count }
        expect { service.close_issue(issue, issue.author) }.to change { ResourceStateEvent.count }
      end
    end

    describe '#reopen_issue' do
      let(:issue) { create(:issue) }

      it { expect(service.reopen_issue(issue, issue.author)).to be_truthy }

      it "creates new event" do
        expect { service.reopen_issue(issue, issue.author) }.to change { Event.count }
        expect { service.reopen_issue(issue, issue.author) }.to change { ResourceStateEvent.count }
      end
    end
  end

  describe 'Merge Requests' do
    describe '#open_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.open_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.open_mr(merge_request, merge_request.author) }.to change { Event.count }
        expect { service.open_mr(merge_request, merge_request.author) }.to change { ResourceStateEvent.count }
      end
    end

    describe '#close_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.close_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.close_mr(merge_request, merge_request.author) }.to change { Event.count }
        expect { service.close_mr(merge_request, merge_request.author) }.to change { ResourceStateEvent.count }
      end
    end

    describe '#merge_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.merge_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.merge_mr(merge_request, merge_request.author) }.to change { Event.count }
        expect { service.merge_mr(merge_request, merge_request.author) }.to change { ResourceStateEvent.count }
      end
    end

    describe '#reopen_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.reopen_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.reopen_mr(merge_request, merge_request.author) }.to change { Event.count }
        expect { service.reopen_mr(merge_request, merge_request.author) }.to change { ResourceStateEvent.count }
      end
    end
  end

  describe 'Milestone' do
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

  shared_examples_for 'service for creating a push event' do |service_class|
    it 'creates a new event' do
      expect { subject }.to change { Event.count }
    end

    it 'creates the push event payload' do
      expect(service_class).to receive(:new)
        .with(an_instance_of(PushEvent), push_data)
        .and_call_original

      subject
    end

    it 'updates user last activity' do
      expect { subject }.to change { user.last_activity_on }.to(Date.today)
    end

    it 'caches the last push event for the user' do
      expect_next_instance_of(Users::LastPushEventService) do |instance|
        expect(instance).to receive(:cache_last_push_event).with(an_instance_of(PushEvent))
      end

      subject
    end

    it 'does not create any event data when an error is raised' do
      payload_service = double(:service)

      allow(payload_service).to receive(:execute)
        .and_raise(RuntimeError)

      allow(service_class).to receive(:new)
        .and_return(payload_service)

      expect { subject }.to raise_error(RuntimeError)
      expect(Event.count).to eq(0)
      expect(PushEventPayload.count).to eq(0)
    end
  end

  describe '#wiki_event' do
    let_it_be(:user) { create(:user) }
    let_it_be(:wiki_page) { create(:wiki_page) }
    let_it_be(:meta) { create(:wiki_page_meta, :for_wiki_page, wiki_page: wiki_page) }

    Event::WIKI_ACTIONS.each do |action|
      context "The action is #{action}" do
        let(:event) { service.wiki_event(meta, user, action) }

        it 'creates the event', :aggregate_failures do
          expect(event).to have_attributes(
            wiki_page?: true,
            valid?: true,
            persisted?: true,
            action: action.to_s,
            wiki_page: wiki_page,
            author: user
          )
        end

        it 'is idempotent', :aggregate_failures do
          expect { event }.to change(Event, :count).by(1)
          duplicate = nil
          expect { duplicate = service.wiki_event(meta, user, action) }.not_to change(Event, :count)

          expect(duplicate).to eq(event)
        end

        context 'the feature is disabled' do
          before do
            stub_feature_flags(wiki_events: false)
          end

          it 'does not create the event' do
            expect { event }.not_to change(Event, :count)
          end
        end
      end
    end

    (Event.actions.keys - Event::WIKI_ACTIONS).each do |bad_action|
      context "The action is #{bad_action}" do
        it 'raises an error' do
          expect { service.wiki_event(meta, user, bad_action) }.to raise_error(described_class::IllegalActionError)
        end
      end
    end
  end

  describe '#push', :clean_gitlab_redis_shared_state do
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

    subject { service.push(project, user, push_data) }

    it_behaves_like 'service for creating a push event', PushEventPayloadService
  end

  describe '#bulk_push', :clean_gitlab_redis_shared_state do
    let(:push_data) do
      {
        action: :created,
        ref_count: 4,
        ref_type: :branch
      }
    end

    subject { service.bulk_push(project, user, push_data) }

    it_behaves_like 'service for creating a push event', BulkPushEventPayloadService
  end

  describe 'Project' do
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

  describe 'design events' do
    let_it_be(:design) { create(:design, project: project) }
    let_it_be(:author) { user }

    shared_examples 'feature flag gated multiple event creation' do
      context 'the feature flag is off' do
        before do
          stub_feature_flags(design_activity_events: false)
        end

        specify { expect(result).to be_empty }
        specify { expect { result }.not_to change { Event.count } }
        specify { expect { result }.not_to exceed_query_limit(0) }
      end

      context 'the feature flag is enabled for a single project' do
        before do
          stub_feature_flags(design_activity_events: project)
        end

        specify { expect(result).not_to be_empty }
        specify { expect { result }.to change { Event.count }.by(1) }
      end
    end

    describe '#save_designs' do
      let_it_be(:updated) { create_list(:design, 5) }
      let_it_be(:created) { create_list(:design, 3) }

      let(:result) { service.save_designs(author, create: created, update: updated) }

      specify { expect { result }.to change { Event.count }.by(8) }

      specify { expect { result }.not_to exceed_query_limit(1) }

      it 'creates 3 created design events' do
        ids = result.pluck('id')
        events = Event.created_action.where(id: ids)

        expect(events.map(&:design)).to match_array(created)
      end

      it 'creates 5 created design events' do
        ids = result.pluck('id')
        events = Event.updated_action.where(id: ids)

        expect(events.map(&:design)).to match_array(updated)
      end

      it_behaves_like 'feature flag gated multiple event creation' do
        let(:project) { created.first.project }
      end
    end

    describe '#destroy_designs' do
      let_it_be(:designs) { create_list(:design, 5) }
      let_it_be(:author) { create(:user) }

      let(:result) { service.destroy_designs(designs, author) }

      specify { expect { result }.to change { Event.count }.by(5) }

      specify { expect { result }.not_to exceed_query_limit(1) }

      it 'creates 5 destroyed design events' do
        ids = result.pluck('id')
        events = Event.destroyed_action.where(id: ids)

        expect(events.map(&:design)).to match_array(designs)
      end

      it_behaves_like 'feature flag gated multiple event creation' do
        let(:project) { designs.first.project }
      end
    end
  end
end
