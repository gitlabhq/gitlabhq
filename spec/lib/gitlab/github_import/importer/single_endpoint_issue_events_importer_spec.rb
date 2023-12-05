# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter, feature_category: :importers do
  let(:client) { double }

  let_it_be(:project) { create(:project, :import_started, import_source: 'http://somegithub.com') }

  let!(:issuable) { create(:issue, project: project) }

  subject { described_class.new(project, client, parallel: parallel) }

  let(:parallel) { true }

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

  describe '#page_counter_id' do
    it { expect(subject.page_counter_id(issuable)).to eq("issues/#{issuable.iid}/issue_timeline") }
  end

  describe '#id_for_already_imported_cache' do
    let(:event) { { id: 1 } }

    it { expect(subject.id_for_already_imported_cache(event)).to eq(1) }
  end

  describe '#collection_options' do
    it do
      expect(subject.collection_options)
        .to eq({ state: 'all', sort: 'created', direction: 'asc' })
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

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let(:issue_event) do
      struct = Struct.new(:id, :event, :created_at, :issue, keyword_init: true)
      struct.new(id: 1, event: 'closed', created_at: '2022-04-26 18:30:53 UTC')
    end

    let(:page) do
      instance_double(
        Gitlab::GithubImport::Client::Page,
        number: 1, objects: [issue_event]
      )
    end

    let(:page_counter) { instance_double(Gitlab::GithubImport::PageCounter) }

    before do
      allow(client).to receive(:each_page)
        .once
        .with(
          :issue_timeline,
          project.import_source,
          issuable.iid,
          { state: 'all', sort: 'created', direction: 'asc', page: 1 }
        ).and_yield(page)
    end

    context 'with issues' do
      it 'imports each issue event page by page' do
        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: 1,
              event: 'closed',
              created_at: '2022-04-26 18:30:53 UTC',
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

    context 'with merge requests' do
      let!(:issuable) { create(:merge_request, source_project: project, target_project: project) }

      it 'imports each merge request event page by page' do
        counter = 0
        subject.each_object_to_import do |object|
          expect(object).to eq(
            {
              id: 1,
              event: 'closed',
              created_at: '2022-04-26 18:30:53 UTC',
              issue: {
                number: issuable.iid,
                pull_request: true
              }
            }
          )
          counter += 1
        end
        expect(counter).to eq 1
      end
    end

    it 'triggers page number increment' do
      expect(Gitlab::GithubImport::PageCounter)
        .to receive(:new).with(project, 'issues/1/issue_timeline')
        .and_return(page_counter)
      expect(page_counter).to receive(:current).and_return(1)
      expect(page_counter)
        .to receive(:set).with(page.number).and_return(true)

      counter = 0
      subject.each_object_to_import { counter += 1 }
      expect(counter).to eq 1
    end

    context 'when page is already processed' do
      before do
        page_counter = Gitlab::GithubImport::PageCounter.new(
          project, subject.page_counter_id(issuable)
        )
        page_counter.set(page.number)
      end

      it "doesn't process this page" do
        counter = 0
        subject.each_object_to_import { counter += 1 }
        expect(counter).to eq 0
      end
    end

    context 'when event is already processed' do
      it "doesn't process this event" do
        subject.mark_as_imported(issue_event)

        counter = 0
        subject.each_object_to_import { counter += 1 }
        expect(counter).to eq 0
      end
    end

    context 'when event is not supported' do
      let(:issue_event) do
        struct = Struct.new(:id, :event, :created_at, :issue, keyword_init: true)
        struct.new(id: 1, event: 'not_supported_event', created_at: '2022-04-26 18:30:53 UTC')
      end

      it "doesn't process this event" do
        counter = 0
        subject.each_object_to_import { counter += 1 }
        expect(counter).to eq 0
      end
    end
  end
end
