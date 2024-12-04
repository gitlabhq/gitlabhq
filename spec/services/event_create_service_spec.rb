# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EventCreateService, :clean_gitlab_redis_cache, :clean_gitlab_redis_shared_state, feature_category: :service_ping do
  include SnowplowHelpers

  let(:service) { described_class.new }
  let(:dates) { { start_date: Date.today.beginning_of_week, end_date: Date.today.next_week } }

  let_it_be(:user, reload: true) { create :user }
  let_it_be(:project) { create(:project) }

  shared_examples 'it records the event in the event counter' do
    specify do
      tracking_params = { event_names: event_action, **dates }

      expect { subject }
        .to change { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**tracking_params) }
        .by(1)
    end
  end

  shared_examples 'it records a git write event' do
    specify do
      tracking_params = { event_names: 'git_write_action', **dates }

      expect { subject }
        .to change { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**tracking_params) }
        .by(1)
    end
  end

  describe 'no project or group' do
    it 'links the event to the personal namespace of the author' do
      author = create(:user, :with_namespace)
      issue = create(:issue, author: author).tap do |issue|
        issue.namespace_id = nil
        issue.project_id = nil
      end

      event = service.open_issue(issue, issue.author)

      expect(event.personal_namespace_id).to eq(issue.author.namespace_id)
    end
  end

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

  describe 'Merge Requests', :snowplow do
    describe '#open_mr' do
      subject(:open_mr) { service.open_mr(merge_request, merge_request.author) }

      let(:merge_request) { create(:merge_request) }

      it { expect(open_mr).to be_truthy }

      it "creates new event" do
        expect { open_mr }.to change { Event.count }
      end

      it_behaves_like "it records the event in the event counter" do
        let(:event_action) { :merge_request_action }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:category) { described_class.name }
        let(:action) { 'created' }
        let(:label) {  described_class::MR_EVENT_LABEL }
        let(:namespace) { project.namespace }
        let(:project) { merge_request.project }
        let(:user) { merge_request.author }
        let(:property) { described_class::MR_EVENT_PROPERTY }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end
      end
    end

    describe '#close_mr' do
      subject(:close_mr) { service.close_mr(merge_request, merge_request.author) }

      let(:merge_request) { create(:merge_request) }

      it { expect(close_mr).to be_truthy }

      it "creates new event" do
        expect { close_mr }.to change { Event.count }
      end

      it_behaves_like "it records the event in the event counter" do
        let(:event_action) { :merge_request_action }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:category) { described_class.name }
        let(:action) { 'closed' }
        let(:label) {  described_class::MR_EVENT_LABEL }
        let(:namespace) { project.namespace }
        let(:project) { merge_request.project }
        let(:user) { merge_request.author }
        let(:property) { described_class::MR_EVENT_PROPERTY }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end
      end
    end

    describe '#merge_mr' do
      subject(:merge_mr) { service.merge_mr(merge_request, merge_request.author) }

      let(:merge_request) { create(:merge_request) }

      it { expect(merge_mr).to be_truthy }

      it "creates new event" do
        expect { merge_mr }.to change { Event.count }
      end

      it_behaves_like "it records the event in the event counter" do
        let(:event_action) { :merge_request_action }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:category) { described_class.name }
        let(:action) { 'merged' }
        let(:label) { described_class::MR_EVENT_LABEL }
        let(:namespace) { project.namespace }
        let(:project) { merge_request.project }
        let(:user) { merge_request.author }
        let(:property) { described_class::MR_EVENT_PROPERTY }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end
      end
    end

    describe '#reopen_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.reopen_mr(merge_request, merge_request.author)).to be_truthy }

      it "creates new event" do
        expect { service.reopen_mr(merge_request, merge_request.author) }.to change { Event.count }
      end
    end

    describe '#approve_mr' do
      let(:merge_request) { create(:merge_request) }

      it { expect(service.approve_mr(merge_request, user)).to be_truthy }

      it 'creates new event' do
        service.approve_mr(merge_request, user)

        change { Event.approved_action.where(target: merge_request).count }.by(1)
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

    it 'publishes an activity event' do
      expect { subject }.to publish_event(Users::ActivityEvent).with({
        user_id: user.id,
        namespace_id: project.root_ancestor.id
      })
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

    let(:fingerprint) { generate(:sha) }

    def create_event
      service.wiki_event(meta, user, action, fingerprint)
    end

    where(:action) { Event::WIKI_ACTIONS.map { |action| [action] } }

    with_them do
      subject { create_event }

      it 'creates the event' do
        expect(create_event).to have_attributes(
          wiki_page?: true,
          valid?: true,
          persisted?: true,
          action: action.to_s,
          wiki_page: wiki_page,
          author: user,
          fingerprint: fingerprint
        )
      end

      it 'is idempotent', :aggregate_failures do
        event = nil
        expect { event = create_event }.to change(Event, :count).by(1)
        duplicate = nil
        expect { duplicate = create_event }.not_to change(Event, :count)

        expect(duplicate).to eq(event)
      end

      it_behaves_like 'internal event tracking' do
        let(:event) { 'performed_wiki_action' }
        let(:category) { described_class.name }
        let(:project) { meta.project }
        let(:additional_properties) { { label: action.to_s } }
      end

      it_behaves_like "it records a git write event"
    end

    (Event.actions.keys - Event::WIKI_ACTIONS).each do |bad_action|
      context "The action is #{bad_action}" do
        let(:action) { bad_action }

        it 'raises an error' do
          expect { create_event }.to raise_error(described_class::IllegalActionError)
        end
      end
    end
  end

  describe '#push', :snowplow do
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

    it_behaves_like "it records the event in the event counter" do
      let(:event_action) { :project_action }
    end

    it_behaves_like "it records a git write event"

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      let(:category) { described_class.to_s }
      let(:action) { :push }
      let(:namespace) { project.namespace }
      let(:label) { 'usage_activity_by_stage_monthly.create.action_monthly_active_users_project_repo' }
      let(:property) { 'project_action' }
    end
  end

  describe '#bulk_push', :snowplow do
    let(:push_data) do
      {
        action: :created,
        ref_count: 4,
        ref_type: :branch
      }
    end

    subject { service.bulk_push(project, user, push_data) }

    it_behaves_like 'service for creating a push event', BulkPushEventPayloadService

    it_behaves_like "it records the event in the event counter" do
      let(:event_action) { :project_action }
    end

    it_behaves_like "it records a git write event"

    it_behaves_like 'Snowplow event tracking with RedisHLL context' do
      let(:category) { described_class.to_s }
      let(:action) { :push }
      let(:namespace) { project.namespace }
      let(:label) { 'usage_activity_by_stage_monthly.create.action_monthly_active_users_project_repo' }
      let(:property) { 'project_action' }
    end
  end

  describe '#join_source' do
    let(:source) { project }

    subject(:join_source) { service.join_source(source, user) }

    context 'when source is a group' do
      let_it_be(:source) { create(:group) }

      it { is_expected.to be_falsey }

      specify do
        expect { join_source }.not_to change { Event.count }
      end
    end

    context 'when source is a project' do
      it { is_expected.to be_truthy }

      specify do
        expect { join_source }.to change { Event.count }.from(0).to(1)
      end
    end
  end

  describe '#expired_leave_project' do
    subject(:expired_leave_project) { service.expired_leave_project(project, user) }

    it { is_expected.to be_truthy }

    specify do
      expect { expired_leave_project }.to change { Event.count }.from(0).to(1)
    end
  end

  describe 'design events', :snowplow do
    let_it_be(:design) { create(:design, project: project) }
    let_it_be(:author) { user }

    before do
      allow(Gitlab::Tracking).to receive(:event) # rubocop:disable RSpec/ExpectGitlabTracking
    end

    describe '#save_designs' do
      let_it_be(:updated) { create_list(:design, 5) }
      let_it_be(:created) { create_list(:design, 3) }

      subject(:result) { service.save_designs(author, create: created, update: updated) }

      specify { expect { result }.to change { Event.count }.by(8) }

      # An addditional query due to event tracking
      specify { expect { result }.not_to exceed_query_limit(2) }

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

      it_behaves_like "it records the event in the event counter" do
        let(:event_action) { :design_action }
      end

      it_behaves_like "it records a git write event"

      describe 'Snowplow tracking' do
        let(:project) { design.project }
        let(:namespace) { project.namespace }
        let(:category) { described_class.name }
        let(:property) { :design_action.to_s }
        let(:label) { ::EventCreateService::DEGIGN_EVENT_LABEL }

        context 'for create event' do
          it_behaves_like 'Snowplow event tracking with RedisHLL context' do
            subject(:design_service) { service.save_designs(author, create: [design]) }

            let(:action) { 'create' }
          end
        end

        context 'for update event' do
          it_behaves_like 'Snowplow event tracking with RedisHLL context' do
            subject(:design_service) { service.save_designs(author, update: [design]) }

            let(:action) { 'update' }
          end
        end
      end
    end

    describe '#destroy_designs' do
      let_it_be(:designs) { create_list(:design, 5) }
      let_it_be(:author) { create(:user) }

      subject(:result) { service.destroy_designs(designs, author) }

      specify { expect { result }.to change { Event.count }.by(5) }

      # An addditional query due to event tracking
      specify { expect { result }.not_to exceed_query_limit(2) }

      it 'creates 5 destroyed design events' do
        ids = result.pluck('id')
        events = Event.destroyed_action.where(id: ids)

        expect(events.map(&:design)).to match_array(designs)
      end

      it_behaves_like "it records the event in the event counter" do
        let(:event_action) { :design_action }
      end

      it_behaves_like "it records a git write event"

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        subject(:design_service) { service.destroy_designs([design], author) }

        let(:project) { design.project }
        let(:namespace) { project.namespace }
        let(:category) { described_class.name }
        let(:action) { 'destroy' }
        let(:user) { author }
        let(:property) { :design_action.to_s }
        let(:label) { ::EventCreateService::DEGIGN_EVENT_LABEL }
      end
    end
  end

  describe '#leave_note', :snowplow do
    subject(:leave_note) { service.leave_note(note, author) }

    let(:note) { create(:note) }
    let(:author) { create(:user) }
    let(:event_action) { :merge_request_action }

    it { expect(leave_note).to be_truthy }

    it "creates new event" do
      expect { leave_note }.to change { Event.count }.by(1)
    end

    context 'when it is a diff note' do
      let(:note) { create(:diff_note_on_merge_request) }

      it_behaves_like "it records the event in the event counter"

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:note) { create(:diff_note_on_merge_request) }
        let(:category) { described_class.name }
        let(:action) { 'commented' }
        let(:property) { described_class::MR_EVENT_PROPERTY }
        let(:label) { described_class::MR_EVENT_LABEL }
        let(:namespace) { project.namespace }
        let(:project) { note.project }
        let(:user) { author }
        let(:context) do
          [Gitlab::Tracking::ServicePingContext.new(data_source: :redis_hll, event: property).to_context]
        end
      end
    end

    context 'when it is not a diff note' do
      it 'does not change the unique action counter' do
        tracking_params = { event_names: event_action, start_date: Date.yesterday, end_date: Date.today }

        expect { subject }.not_to change { Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(**tracking_params) }
      end
    end
  end
end
