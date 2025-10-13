# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter, feature_category: :importers do
  let(:client) { Gitlab::GithubImport::Client.new('token') }
  let_it_be(:project) { create(:project, :import_started, import_source: 'foo/bar') }
  let!(:issuable) { create(:issue, project: project) }
  let(:parallel) { true }

  subject { described_class.new(project, client, parallel: parallel) }

  it { is_expected.to include_module(Gitlab::GithubImport::ParallelScheduling) }

  describe '#importer_class' do
    it { expect(subject.importer_class).to eq(Gitlab::GithubImport::Importer::IssueEventImporter) }
  end

  describe '#representation_class' do
    it { expect(subject.representation_class).to eq(Gitlab::GithubImport::Representation::IssueEvent) }
  end

  describe '#sidekiq_worker_class' do
    it { expect(subject.sidekiq_worker_class).to eq(Gitlab::GithubImport::ImportIssueEventWorker) }
  end

  describe '#object_type' do
    it { expect(subject.object_type).to eq(:issue_event) }
  end

  describe '#collection_method' do
    it { expect(subject.collection_method).to eq(:issue_timeline) }
  end

  describe '#page_keyset_id' do
    it { expect(subject.page_keyset_id(issuable)).to eq("issues/#{issuable.iid}/issue_timeline") }
  end

  describe '#id_for_already_imported_cache' do
    let(:event) { { id: 1 } }

    it { expect(subject.id_for_already_imported_cache(event)).to eq(1) }
  end

  describe '#collection_options' do
    it do
      expect(subject.collection_options).to eq({})
    end
  end

  describe '#compose_associated_id!' do
    let(:issuable) { build_stubbed(:issue, iid: 99) }
    let(:event_resource) { Struct.new(:id, :event, :source, keyword_init: true) }

    context 'when event type is cross-referenced' do
      let(:event) do
        source_resource = Struct.new(:issue, keyword_init: true)
        issue_resource = Struct.new(:id, keyword_init: true)
        event_resource.new(
          id: nil,
          event: 'cross-referenced',
          source: source_resource.new(issue: issue_resource.new(id: '100500'))
        )
      end

      it 'assigns event id' do
        subject.compose_associated_id!(issuable, event)

        expect(event.id).to eq 'cross-reference#99-in-100500'
      end
    end

    context "when event type isn't cross-referenced" do
      let(:event) { event_resource.new(id: nil, event: 'labeled') }

      it "doesn't assign event id" do
        subject.compose_associated_id!(issuable, event)

        expect(event.id).to eq nil
      end
    end
  end

  describe '#each_object_to_import', :clean_gitlab_redis_shared_state do
    let(:event_name) { 'closed' }
    let(:event_1) do
      {
        id: 1,
        event: event_name,
        created_at: '2022-04-26 18:30:53 UTC'
      }
    end

    let(:event_2) do
      {
        id: 2,
        event: event_name,
        created_at: '2022-04-26 18:30:53 UTC'
      }
    end

    before do
      allow(client)
        .to receive(:with_rate_limit)
        .and_yield

      stub_request(:get,
        "https://api.github.com/repos/foo/bar/issues/1/timeline?per_page=100")
          .to_return(
            status: 200,
            body: [event_1].to_json,
            headers: {
              'Content-Type' => 'application/json',
              'Link' => '<https://api.github.com/repositories/1/issues/1/timelint?per_page=100&page=2>; rel="next"'
            }
          )

      stub_request(:get,
        "https://api.github.com/repositories/1/issues/1/timelint?per_page=100&page=2")
          .to_return(
            status: 200,
            body: [event_2].to_json,
            headers: {
              'Content-Type' => 'application/json'
            }
          )
    end

    context 'with issues' do
      it 'imports each issue event page by page' do
        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: counter + 1,
              event: event_name,
              created_at: '2022-04-26 18:30:53.000000000 +0000',
              issue: {
                number: issuable.iid,
                pull_request: false
              }
            }
          )
          counter += 1
        end
        expect(counter).to eq 2
      end
    end

    context 'with merge requests' do
      let!(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it 'imports each merge request event page by page' do
        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: counter + 1,
              event: event_name,
              created_at: '2022-04-26 18:30:53.000000000 +0000',
              issue: {
                number: issuable.iid,
                pull_request: true
              }
            }
          )
          counter += 1
        end
        expect(counter).to eq 2
      end
    end

    context 'when page key set stores an URL' do
      before do
        allow_next_instance_of(Gitlab::Import::PageKeyset) do |page_keyset|
          allow(page_keyset).to receive(:current).and_return(
            "https://api.github.com/repositories/1/issues/1/timelint?per_page=100&page=2"
          )
        end
      end

      it 'resumes from the stored URL' do
        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: event_2[:id],
              event: event_name,
              created_at: '2022-04-26 18:30:53.000000000 +0000',
              issue: {
                number: issuable.iid,
                pull_request: false
              }
            }
          )
          counter += 1
        end
        expect(counter).to eq 1
      end
    end

    context 'when event is already processed' do
      it "doesn't process the event" do
        subject.mark_as_imported(event_1)

        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: event_2[:id],
              event: event_name,
              created_at: '2022-04-26 18:30:53.000000000 +0000',
              issue: {
                number: issuable.iid,
                pull_request: false
              }
            }
          )
          counter += 1
        end
        expect(counter).to eq 1
      end
    end

    context 'when event is not supported' do
      let(:event_name) { 'not_supported_event' }

      it "doesn't process the event" do
        counter = 0
        subject.each_object_to_import { counter += 1 }
        expect(counter).to eq 0
      end
    end

    describe 'increment object counter' do
      it 'increments counter' do
        expect(Gitlab::GithubImport::ObjectCounter).to receive(:increment).with(project, :issue_event, :fetched).twice

        subject.each_object_to_import { |event| event }
      end

      context 'when event should increment a mapped fetched counter' do
        before do
          stub_const('Gitlab::GithubImport::Importer::IssueEventImporter::EVENT_COUNTER_MAP', {
            'closed' => 'custom_type'
          })
        end

        it 'increments the mapped fetched counter' do
          expect(Gitlab::GithubImport::ObjectCounter).to receive(:increment).with(project, 'custom_type',
            :fetched).twice

          subject.each_object_to_import { |event| event }
        end
      end
    end

    describe 'save events' do
      shared_examples 'saves event' do
        it 'saves event' do
          expect(Gitlab::GithubImport::Representation::IssueEvent).to receive(:from_api_response).with(
            a_hash_including(id: event_1[:id])).and_call_original

          expect(Gitlab::GithubImport::Representation::IssueEvent).to receive(:from_api_response).with(
            a_hash_including(id: event_2[:id])).and_call_original

          expect_next_instance_of(Gitlab::GithubImport::EventsCache) do |events_cache|
            expect(events_cache).to receive(:add).with(
              issuable,
              an_instance_of(Gitlab::GithubImport::Representation::IssueEvent)
            ).twice
          end

          subject.each_object_to_import { |event| event }
        end
      end

      context 'when event is review_requested' do
        let(:event_name) { 'review_requested' }

        it_behaves_like 'saves event'
      end

      context 'when event is review_request_removed' do
        let(:event_name) { 'review_request_removed' }

        it_behaves_like 'saves event'
      end

      context 'when event is closed' do
        let(:event_name) { 'closed' }

        it 'does not save event' do
          expect_next_instance_of(Gitlab::GithubImport::EventsCache) do |events_cache|
            expect(events_cache).not_to receive(:add)
          end

          subject.each_object_to_import { |event| event }
        end
      end
    end

    describe 'after batch processed' do
      context 'when events should be replayed' do
        let(:event_name) { 'review_requested' }

        it 'enqueues worker to replay events' do
          allow(Gitlab::JobWaiter).to receive(:generate_key).and_return('job_waiter_key')

          expect(Gitlab::GithubImport::ReplayEventsWorker).to receive(:perform_async)
            .with(
              project.id,
              { 'issuable_type' => issuable.class.name.to_s, 'issuable_iid' => issuable.iid },
              'job_waiter_key'
            )

          subject.each_object_to_import { |event| event }
        end
      end

      context 'when events are not relevant' do
        let(:event_name) { 'closed' }

        it 'does not replay events' do
          expect(Gitlab::GithubImport::ReplayEventsWorker).not_to receive(:perform_async)

          subject.each_object_to_import { |event| event }
        end
      end
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state do
    before do
      stub_request(:get, 'https://api.github.com/rate_limit')
        .to_return(status: 200, headers: { 'X-RateLimit-Limit' => 5000, 'X-RateLimit-Remaining' => 5000 })

      events = [
        {
          id: 1,
          event: 'review_requested',
          created_at: '2022-04-26 18:30:53 UTC',
          issue: {
            number: issuable.iid,
            pull_request: true
          }
        }
      ]

      stub_request(:get, 'https://api.github.com/repos/foo/bar/issues/1/timeline?per_page=100')
        .to_return(status: 200, body: events.to_json, headers: { 'Content-Type' => 'application/json' })
    end

    it 'enqueues importer worker and replay worker' do
      expect { subject.execute }.to change { Gitlab::GithubImport::ReplayEventsWorker.jobs.size }.by(1)
      .and change { Gitlab::GithubImport::ImportIssueEventWorker.jobs.size }.by(1)
    end

    it 'returns job waiter with the correct remaining jobs count' do
      job_waiter = subject.execute

      expect(job_waiter.jobs_remaining).to eq(2)
    end
  end
end
