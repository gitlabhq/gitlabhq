# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::SingleEndpointIssueEventsImporter do
  let(:client) { double }

  let_it_be(:project) { create(:project, :import_started, import_source: 'http://somegithub.com') }
  let_it_be(:issue) { create(:issue, project: project) }

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
    it { expect(subject.page_counter_id(issue)).to eq("issues/#{issue.iid}/issue_timeline") }
  end

  describe '#id_for_already_imported_cache' do
    let(:event) { instance_double('Event', id: 1) }

    it { expect(subject.id_for_already_imported_cache(event)).to eq(1) }
  end

  describe '#collection_options' do
    it do
      expect(subject.collection_options)
        .to eq({ state: 'all', sort: 'created', direction: 'asc' })
    end
  end

  describe '#each_object_to_import', :clean_gitlab_redis_cache do
    let(:issue_event) do
      struct = Struct.new(:id, :event, :created_at, :issue_db_id, keyword_init: true)
      struct.new(id: rand(10), event: 'closed', created_at: '2022-04-26 18:30:53 UTC')
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
          issue.iid,
          { state: 'all', sort: 'created', direction: 'asc', page: 1 }
        ).and_yield(page)
    end

    it 'imports each issue event page by page' do
      counter = 0
      subject.each_object_to_import do |object|
        expect(object).to eq issue_event
        expect(issue_event.issue_db_id).to eq issue.id
        counter += 1
      end
      expect(counter).to eq 1
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
          project, subject.page_counter_id(issue)
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
  end
end
