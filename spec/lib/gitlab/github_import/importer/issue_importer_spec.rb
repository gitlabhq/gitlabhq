# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::IssueImporter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be(:work_item_type_id) { build(:work_item_system_defined_type, :issue).id }
  let_it_be(:group) { create(:group) }

  let_it_be_with_reload(:project) do
    create(
      :project, :github_import,
      :import_user_mapping_enabled,
      group: group
    )
  end

  let_it_be(:milestone) { create(:milestone, project: project) }

  let(:client) { instance_double(Gitlab::GithubImport::Client, web_endpoint: 'https://github.com') }
  let(:created_at) { Time.new(2017, 1, 1, 12, 00) }
  let(:updated_at) { Time.new(2017, 1, 1, 12, 15) }
  let(:description) { 'This is my issue' }
  let(:author) { Gitlab::GithubImport::Representation::User.new(id: 4, login: 'alice') }
  let(:bob) { Gitlab::GithubImport::Representation::User.new(id: 5, login: 'bob') }
  let(:assignees) { [author, bob] }

  let(:issue) do
    Gitlab::GithubImport::Representation::Issue.new(
      iid: 42,
      title: 'My Issue',
      description: description,
      milestone_number: 1,
      state: :opened,
      assignees: assignees,
      label_names: %w[bug],
      author: author,
      created_at: created_at,
      updated_at: updated_at,
      pull_request: false,
      work_item_type_id: work_item_type_id
    )
  end

  let_it_be(:source_user_alice) { generate_source_user(project, '4') }
  let_it_be(:source_user_bob) { generate_source_user(project, '5') }

  let(:cached_references) { placeholder_user_references(::Import::SOURCE_GITHUB, project.import_state.id) }

  subject(:importer) { described_class.new(issue, project, client) }

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
    it 'creates the issue' do
      expect { importer.execute }.to change { Issue.count }.by(1)

      expect(Issue.last).to have_attributes(
        iid: 42,
        title: 'My Issue',
        author_id: source_user_alice.mapped_user_id,
        assignee_ids: contain_exactly(source_user_bob.mapped_user_id, source_user_alice.mapped_user_id),
        project_id: project.id,
        namespace_id: project.project_namespace_id,
        description: "This is my issue",
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

    it 'pushes the author and assignee references' do
      importer.execute

      created_issue = Issue.last

      expect(cached_references).to match_array([
        ['Issue', created_issue.id, 'author_id', source_user_alice.id],
        [
          'IssueAssignee', { 'user_id' => source_user_alice.mapped_user_id, 'issue_id' => created_issue.id },
          'user_id', source_user_alice.id
        ],
        [
          'IssueAssignee', { 'user_id' => source_user_bob.mapped_user_id, 'issue_id' => created_issue.id },
          'user_id', source_user_bob.id
        ]
      ])
    end

    context 'when the description is processed for formatting' do
      let(:description) { 'You can ask @knejad by emailing xyz@gitlab.com' }

      before do
        allow(Gitlab::GithubImport::MarkdownText).to receive(:format).and_call_original

        importer.execute
      end

      it 'verify that the formatted description using MarkdownText equals the expected description' do
        expect(Gitlab::GithubImport::MarkdownText).to have_received(:format)
        expect(Issue.last.description).to eq("You can ask `@knejad` by emailing xyz@gitlab.com")
      end
    end

    context 'when direct reassignment is supported' do
      before do
        allow(Import::DirectReassignService).to receive(:supported?).and_return(true)
      end

      it 'does not push any placeholder references' do
        importer.execute

        expect(cached_references).to be_empty
      end
    end

    context 'when the issue has no author' do
      let(:author) { nil }
      let(:assignees) { [bob] }

      it 'imports the issue as the ghost user and pushes only the assignee reference' do
        importer.execute

        created_issue = Issue.last

        expect(created_issue.author_id).to eq(Users::Internal.in_organization(project.organization).ghost.id)
        expect(cached_references).to contain_exactly(
          [
            'IssueAssignee', { 'user_id' => source_user_bob.mapped_user_id, 'issue_id' => created_issue.id },
            'user_id', source_user_bob.id
          ]
        )
      end
    end

    context 'when an assignee is the GitHub ghost user' do
      let(:assignees) { [author, Gitlab::GithubImport::Representation::User.new(id: 6, login: 'ghost')] }

      it 'skips the ghost assignee and pushes references only for mapped users' do
        importer.execute

        created_issue = Issue.last

        expect(created_issue.assignee_ids).to contain_exactly(source_user_alice.mapped_user_id)
        expect(cached_references).to contain_exactly(
          ['Issue', created_issue.id, 'author_id', source_user_alice.id],
          [
            'IssueAssignee', { 'user_id' => source_user_alice.mapped_user_id, 'issue_id' => created_issue.id },
            'user_id', source_user_alice.id
          ]
        )
      end
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }

      before_all do
        project.update!(namespace: user_namespace)
      end

      it 'does not push any references' do
        importer.execute

        expect(cached_references).to be_empty
      end

      it 'imports the issue mapped to the personal namespace owner' do
        expect { importer.execute }.to change { Issue.count }.by(1)

        expect(Issue.last).to have_attributes(
          iid: 42,
          title: 'My Issue',
          author_id: user_namespace.owner_id,
          assignee_ids: contain_exactly(user_namespace.owner_id)
        )
      end
    end
  end

  describe '#import_attributes' do
    it 'resolves the author only once when called repeatedly' do
      expect(importer.user_finder).to receive(:author_id_for).once.and_call_original

      2.times { importer.import_attributes }
    end

    it 'returns the attributes used to create the issue' do
      expect(importer.import_attributes).to include(
        iid: 42,
        title: 'My Issue',
        author_id: source_user_alice.mapped_user_id,
        assignee_ids: contain_exactly(source_user_alice.mapped_user_id, source_user_bob.mapped_user_id),
        project_id: project.id,
        milestone_id: milestone.id,
        imported_from: ::Import::SOURCE_GITHUB
      )
    end
  end

  describe '#push_placeholder_references' do
    it 'pushes the author and assignee references for an existing issue' do
      created_issue = project.issues.create!(importer.import_attributes.merge(importing: true))

      importer.push_placeholder_references(created_issue)

      expect(cached_references).to include(
        ['Issue', created_issue.id, 'author_id', source_user_alice.id]
      )
      expect(cached_references.size).to eq(3)
    end
  end
end
