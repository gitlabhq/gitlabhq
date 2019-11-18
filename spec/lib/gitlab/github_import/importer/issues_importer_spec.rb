# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::IssuesImporter do
  let(:project) { double(:project, id: 4, import_source: 'foo/bar') }
  let(:client) { double(:client) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  let(:github_issue) do
    double(
      :response,
      number: 42,
      title: 'My Issue',
      body: 'This is my issue',
      milestone: double(:milestone, number: 4),
      state: 'open',
      assignees: [double(:user, id: 4, login: 'alice')],
      labels: [double(:label, name: 'bug')],
      user: double(:user, id: 4, login: 'alice'),
      created_at: created_at,
      updated_at: updated_at,
      pull_request: false
    )
  end

  describe '#parallel?' do
    it 'returns true when running in parallel mode' do
      importer = described_class.new(project, client)
      expect(importer).to be_parallel
    end

    it 'returns false when running in sequential mode' do
      importer = described_class.new(project, client, parallel: false)
      expect(importer).not_to be_parallel
    end
  end

  describe '#execute' do
    context 'when running in parallel mode' do
      it 'imports issues in parallel' do
        importer = described_class.new(project, client)

        expect(importer).to receive(:parallel_import)

        importer.execute
      end
    end

    context 'when running in sequential mode' do
      it 'imports issues in sequence' do
        importer = described_class.new(project, client, parallel: false)

        expect(importer).to receive(:sequential_import)

        importer.execute
      end
    end
  end

  describe '#sequential_import' do
    it 'imports each issue in sequence' do
      importer = described_class.new(project, client, parallel: false)
      issue_importer = double(:importer)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(github_issue)

      expect(Gitlab::GithubImport::Importer::IssueAndLabelLinksImporter)
        .to receive(:new)
        .with(
          an_instance_of(Gitlab::GithubImport::Representation::Issue),
          project,
          client
        )
        .and_return(issue_importer)

      expect(issue_importer).to receive(:execute)

      importer.sequential_import
    end
  end

  describe '#parallel_import' do
    it 'imports each issue in parallel' do
      importer = described_class.new(project, client)

      allow(importer)
        .to receive(:each_object_to_import)
        .and_yield(github_issue)

      expect(Gitlab::GithubImport::ImportIssueWorker)
        .to receive(:perform_async)
        .with(project.id, an_instance_of(Hash), an_instance_of(String))

      waiter = importer.parallel_import

      expect(waiter).to be_an_instance_of(Gitlab::JobWaiter)
      expect(waiter.jobs_remaining).to eq(1)
    end
  end

  describe '#id_for_already_imported_cache' do
    it 'returns the issue number of the given issue' do
      importer = described_class.new(project, client)

      expect(importer.id_for_already_imported_cache(github_issue))
        .to eq(42)
    end
  end
end
