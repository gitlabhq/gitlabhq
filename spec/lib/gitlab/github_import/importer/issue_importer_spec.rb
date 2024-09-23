# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::IssueImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:work_item_type_id) { ::WorkItems::Type.default_issue_type.id }
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:user_2) { create(:user) }
  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client) }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:description) { 'This is my issue' }

  let(:issue) do
    Gitlab::GithubImport::Representation::Issue.new(
      iid: 42,
      title: 'My Issue',
      description: description,
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
      pull_request: false,
      work_item_type_id: work_item_type_id
    )
  end

  describe '.import_if_issue' do
    it 'imports an issuable if it is a regular issue' do
      expect_next_instance_of(Gitlab::GithubImport::Importer::IssueImporter, issue, project, client) do |importer|
        expect(importer).to receive(:execute)
      end

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

    before do
      allow_next_instance_of(Gitlab::GithubImport::MilestoneFinder) do |finder|
        allow(finder).to receive(:id_for).with(issue).and_return(milestone.id)
      end

      allow_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
        allow(finder).to receive(:author_id_for).with(issue).and_return([project.creator_id, false])
        allow(finder).to receive(:user_id_for).and_return(nil)
      end
    end

    it 'creates the issue' do
      expect { importer.execute }.to change { Issue.count }.by(1)
      expect(Issue.last).to have_attributes(
        iid: 42,
        title: 'My Issue',
        author_id: project.creator_id,
        assignee_ids: [],
        project_id: project.id,
        namespace_id: project.project_namespace_id,
        description: "*Created by: alice*\n\nThis is my issue",
        milestone_id: milestone.id,
        state_id: 1,
        created_at: created_at,
        updated_at: updated_at,
        work_item_type_id: work_item_type_id,
        imported_from: 'github'
      )
    end

    it 'caches the created issue ID' do
      importer.execute

      database_id = Gitlab::GithubImport::IssuableFinder.new(project, issue).database_id

      expect(database_id).to eq(Issue.last.id)
    end

    context 'when author is mapped to a user' do
      it 'sets the author ID to the mapped user and preserves the original issue description' do
        expect_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          expect(finder).to receive(:author_id_for).and_return([user.id, true])
          expect(finder).to receive(:user_id_for).and_return(nil).twice
        end

        importer.execute

        expect(Issue.last).to have_attributes(
          description: "This is my issue",
          author_id: user.id
        )
      end
    end

    context 'when assigness are mapped to users' do
      it 'sets the assignee IDs to the mapped users' do
        expect_next_instance_of(Gitlab::GithubImport::UserFinder) do |finder|
          expect(finder).to receive(:author_id_for).and_return([user.id, true])
          expect(finder).to receive(:user_id_for).and_return(user.id)
          expect(finder).to receive(:user_id_for).and_return(user_2.id)
        end

        importer.execute

        expect(Issue.last.assignee_ids).to match_array([user.id, user_2.id])
      end
    end

    context 'when the description has user mentions' do
      let(:description) { 'You can ask @knejad by emailing xyz@gitlab.com' }

      it 'adds backticks to the username' do
        importer.execute

        expect(Issue.last.description).to eq("*Created by: alice*\n\nYou can ask `@knejad` by emailing xyz@gitlab.com")
      end
    end
  end
end
