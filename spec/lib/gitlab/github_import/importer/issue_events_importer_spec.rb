# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::IssueEventsImporter, feature_category: :importers do
  subject(:importer) { described_class.new(project, client, parallel: parallel) }

  let(:project) { build(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { instance_double(Gitlab::GithubImport::Client) }

  let(:parallel) { true }
  let(:issue_event) do
    struct = Struct.new(
      :id, :node_id, :url, :actor, :event, :commit_id, :commit_url, :label, :rename, :milestone, :source,
      :assignee, :assigner, :review_requester, :requested_reviewer, :issue, :created_at, :performed_via_github_app,
      keyword_init: true
    )
    struct.new(id: rand(10), event: 'closed', created_at: '2022-04-26 18:30:53 UTC')
  end

  describe '#parallel?' do
    context 'when running in parallel mode' do
      it { expect(importer).to be_parallel }
    end

    context 'when running in sequential mode' do
      let(:parallel) { false }

      it { expect(importer).not_to be_parallel }
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports events in parallel' do
        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      let(:parallel) { false }

      it 'imports notes in sequence' do
        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    let(:parallel) { false }

    it 'imports each event in sequence' do
      event_importer = instance_double(Gitlab::GithubImport::Importer::IssueEventImporter)

      allow(importer).to receive(:each_object_to_import).and_yield(issue_event)

      expect(Gitlab::GithubImport::Importer::IssueEventImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::IssueEvent),
          project,
          client
        )
        .and_return(event_importer)

      expect(event_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import', :clean_gitlab_redis_cache do
    before do
      allow(Gitlab::Redis::SharedState).to receive(:with).and_return('OK')
    end

    it 'imports each note in parallel' do
      allow(importer).to receive(:each_object_to_import).and_yield(issue_event)

      expect(Gitlab::GithubImport::ImportIssueEventWorker).to receive(:perform_in).with(
        1, project.id, an_instance_of(Hash), an_instance_of(String)
      )

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#importer_class' do
    it { expect(importer.importer_class).to eq Gitlab::GithubImport::Importer::IssueEventImporter }
  end

  describe '#representation_class' do
    it { expect(importer.representation_class).to eq Gitlab::GithubImport::Representation::IssueEvent }
  end

  describe '#sidekiq_worker_class' do
    it { expect(importer.sidekiq_worker_class).to eq Gitlab::GithubImport::ImportIssueEventWorker }
  end

  describe '#object_type' do
    it { expect(importer.object_type).to eq :issue_event }
  end

  describe '#collection_method' do
    it { expect(importer.collection_method).to eq :repository_issue_events }
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the ID of the given note' do
      expect(importer.id_for_already_imported_cache(issue_event)).to eq(issue_event.id)
    end
  end

  describe '#collection_options' do
    it { expect(importer.collection_options).to eq({}) }
  end
end
