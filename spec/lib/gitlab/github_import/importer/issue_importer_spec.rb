# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::IssueImporter, :clean_gitlab_redis_cache do
  let(:project) { create(:project) }
  let(:client) { double(:client) }
  let(:user) { create(:user) }
  let(:milestone) { create(:milestone, project: project) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }

  let(:issue) do
    Gitlab::GithubImport::Representation::Issue.new(
      iid: 42,
      title: 'My Issue',
      description: 'This is my issue',
      milestone_number: 1,
      state: :opened,
      assignees: [
        Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice'),
        Gitlab::GithubImport::Representation::User.new(id: 5, login: 'bob')
      ],
      label_names: %w[bug],
      author: Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice'),
      created_at: created_at,
      updated_at: updated_at,
      pull_request: false
    )
  end

  describe '.import_if_issue' do
    it 'imports an issuable if it is a regular issue' do
      importer = double(:importer)

      expect(described_class)
        .to receive(:new)
        .with(issue, project, client)
        .and_return(importer)

      expect(importer).to receive(:execute)

      described_class.import_if_issue(issue, project, client)
    end

    it 'does not import the issuable if it is a pull request' do
      expect(issue).to receive(:pull_request?).and_return(true)

      expect(described_class).not_to receive(:new)

      described_class.import_if_issue(issue, project, client)
    end
  end

  describe '#execute' do
    let(:importer) { described_class.new(issue, project, client) }

    it 'creates the issue and assignees' do
      expect(importer)
        .to receive(:create_issue)
        .and_return(10)

      expect(importer)
        .to receive(:create_assignees)
        .with(10)

      expect(importer.issuable_finder)
        .to receive(:cache_database_id)
        .with(10)

      importer.execute
    end
  end

  describe '#create_issue' do
    let(:importer) { described_class.new(issue, project, client) }

    before do
      allow(importer.milestone_finder)
        .to receive(:id_for)
        .with(issue)
        .and_return(milestone.id)
    end

    context 'when the issue author could be found' do
      it 'creates the issue with the found author as the issue author' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(issue)
          .and_return([user.id, true])

        expect(importer)
          .to receive(:insert_and_return_id)
          .with(
            {
              iid: 42,
              title: 'My Issue',
              author_id: user.id,
              project_id: project.id,
              description: 'This is my issue',
              milestone_id: milestone.id,
              state_id: 1,
              created_at: created_at,
              updated_at: updated_at
            },
            project.issues
          )
          .and_call_original

        importer.create_issue
      end
    end

    context 'when the issue author could not be found' do
      it 'creates the issue with the project creator as the issue author' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(issue)
          .and_return([project.creator_id, false])

        expect(importer)
          .to receive(:insert_and_return_id)
          .with(
            {
              iid: 42,
              title: 'My Issue',
              author_id: project.creator_id,
              project_id: project.id,
              description: "*Created by: alice*\n\nThis is my issue",
              milestone_id: milestone.id,
              state_id: 1,
              created_at: created_at,
              updated_at: updated_at
            },
            project.issues
          )
          .and_call_original

        importer.create_issue
      end
    end

    context 'when the import fails due to a foreign key error' do
      it 'does not raise any errors' do
        allow(importer.user_finder)
          .to receive(:author_id_for)
          .with(issue)
          .and_return([user.id, true])

        expect(importer)
          .to receive(:insert_and_return_id)
          .and_raise(ActiveRecord::InvalidForeignKey, 'invalid foreign key')

        expect { importer.create_issue }.not_to raise_error
      end
    end

    it 'produces a valid Issue' do
      allow(importer.user_finder)
        .to receive(:author_id_for)
        .with(issue)
        .and_return([user.id, true])

      importer.create_issue

      expect(project.issues.take).to be_valid
    end

    it 'returns the ID of the created issue' do
      allow(importer.user_finder)
        .to receive(:author_id_for)
        .with(issue)
        .and_return([user.id, true])

      expect(importer.create_issue).to be_a_kind_of(Numeric)
    end
  end

  describe '#create_assignees' do
    it 'inserts the issue assignees in bulk' do
      importer = described_class.new(issue, project, client)

      allow(importer.user_finder)
        .to receive(:user_id_for)
        .with(issue.assignees[0])
        .and_return(4)

      allow(importer.user_finder)
        .to receive(:user_id_for)
        .with(issue.assignees[1])
        .and_return(5)

      expect(Gitlab::Database)
        .to receive(:bulk_insert)
        .with(
          IssueAssignee.table_name,
          [{ issue_id: 1, user_id: 4 }, { issue_id: 1, user_id: 5 }]
        )

      importer.create_assignees(1)
    end
  end
end
