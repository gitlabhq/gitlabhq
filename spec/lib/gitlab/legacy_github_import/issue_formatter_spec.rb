# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::IssueFormatter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::GiteaHelper

  let_it_be(:project) do
    create(
      :project,
      :with_import_url,
      :import_user_mapping_enabled,
      :in_group,
      import_type: ::Import::SOURCE_GITEA)
  end

  let_it_be(:source_user_mapper) do
    Gitlab::Import::SourceUserMapper.new(
      namespace: project.root_ancestor,
      import_type: project.import_type,
      source_hostname: 'https://gitea.com'
    )
  end

  let_it_be(:octocat) { { id: 123456, login: 'octocat', email: 'octocat@example.com' } }
  let_it_be(:import_source_user) do
    create(
      :import_source_user,
      source_user_identifier: octocat[:id],
      namespace: project.root_ancestor,
      source_hostname: 'https://gitea.com',
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let(:client) { instance_double(Gitlab::LegacyGithubImport::Client) }
  let(:ghost_user) { { id: -1, login: 'Ghost' } }
  let(:created_at) { DateTime.strptime('2011-01-26T19:01:12Z') }
  let(:updated_at) { DateTime.strptime('2011-01-27T19:01:12Z') }
  let(:imported_from) { ::Import::SOURCE_GITEA }
  let(:base_data) do
    {
      number: 1347,
      milestone: nil,
      state: 'open',
      title: 'Found a bug',
      body: "I'm having a problem with this.",
      assignee: nil,
      user: octocat,
      comments: 0,
      pull_request: nil,
      created_at: created_at,
      updated_at: updated_at,
      closed_at: nil
    }
  end

  subject(:issue) { described_class.new(project, raw_data, client, source_user_mapper) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  shared_examples 'Gitlab::LegacyGithubImport::IssueFormatter#attributes' do
    context 'when issue is open' do
      let(:raw_data) { base_data.merge(state: 'open') }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          project: project,
          milestone: nil,
          title: 'Found a bug',
          description: "I'm having a problem with this.",
          state: 'opened',
          author_id: import_source_user.placeholder_user_id,
          assignee_ids: [],
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(issue.attributes).to eq(expected)
      end
    end

    context 'when issue is closed' do
      let(:raw_data) { base_data.merge(state: 'closed') }

      it 'returns formatted attributes' do
        expected = {
          iid: 1347,
          project: project,
          milestone: nil,
          title: 'Found a bug',
          description: "I'm having a problem with this.",
          state: 'closed',
          author_id: import_source_user.placeholder_user_id,
          assignee_ids: [],
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(issue.attributes).to eq(expected)
      end
    end

    context 'when the issue body has @username mentions' do
      let(:original_body) { "I said to @sam_allen.greg the code should follow @bob's advice. @.ali-ce/group#9?" }
      let(:expected_body) { "I said to `@sam_allen.greg` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }
      let(:raw_data) { base_data.merge(body: original_body) }

      it 'places backtick around @username mentions' do
        expect(issue.attributes[:description]).to eq(expected_body)
      end
    end

    context 'when it is assigned to a user' do
      context 'and the assigned user has a placeholder user in gitlab' do
        let(:raw_data) { base_data.merge(assignee: octocat) }

        it 'returns an existing placeholder user id' do
          expect(issue.attributes.fetch(:assignee_ids)).to eq([import_source_user.placeholder_user_id])
        end
      end

      context 'and the assigned user does not already have a placeholder user' do
        let(:octocat_2) { { id: 999999, login: 'octocat two', email: 'octocat2@example.com' } }
        let(:raw_data) { base_data.merge(assignee: octocat_2) }

        it 'creates and returns a new placeholder user id', :aggregate_failures do
          assignee_id = issue.attributes.fetch(:assignee_ids).first

          expect(User.find(assignee_id).user_type).to eq('placeholder')
          expect(assignee_id).not_to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and it is assigned to a deleted gitea user' do
        let(:raw_data) { base_data.merge(assignee: ghost_user) }

        it 'returns nil for assignee_ids' do
          expect(issue.attributes.fetch(:assignee_ids)).to be_empty
        end
      end

      context 'and user contribution mapping is disabled' do
        let(:raw_data) { base_data.merge(assignee: octocat) }

        before do
          stub_user_mapping_chain(project, false)
        end

        it 'returns nil as assignee_id when is not a GitLab user' do
          expect(issue.attributes.fetch(:assignee_ids)).to be_empty
        end

        it 'does not create any placeholder users' do
          expect { issue.attributes.fetch(:assignee_ids) }.not_to change {
            User.where(user_type: :placeholder).count
          }
        end

        it 'returns GitLab user id associated with Gitea email as assignee_id' do
          gl_user = create(:user, email: octocat[:email])

          expect(issue.attributes.fetch(:assignee_ids)).to eq [gl_user.id]
        end
      end
    end

    context 'when it has a milestone' do
      let(:milestone) { { id: 42, number: 42 } }
      let(:raw_data) { base_data.merge(milestone: milestone) }

      it 'returns nil when milestone does not exist' do
        expect(issue.attributes.fetch(:milestone)).to be_nil
      end

      it 'returns milestone when it exists' do
        milestone = create(:milestone, project: project, iid: 42)

        expect(issue.attributes.fetch(:milestone)).to eq milestone
      end
    end

    context 'when the issue has an author' do
      context 'and the author has a placeholder user in gitlab' do
        let(:raw_data) { base_data.merge(user: octocat) }

        it 'returns an existing placeholder user id' do
          expect(issue.attributes.fetch(:author_id)).to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and the author does not already have a placeholder user' do
        let(:octocat_2) { { id: 999999, login: 'octocat two', email: 'octocat2@example.com' } }
        let(:raw_data) { base_data.merge(user: octocat_2) }

        it 'creates and returns a new placeholder user id', :aggregate_failures do
          author_id = issue.attributes.fetch(:author_id)
          expect(User.find(author_id).user_type).to eq('placeholder')
          expect(author_id).not_to eq(import_source_user.placeholder_user_id)
        end
      end

      context 'and the author is a deleted gitea user' do
        let(:raw_data) { base_data.merge(user: ghost_user) }

        it 'returns the project creator id' do
          expect(issue.attributes.fetch(:author_id)).to eq(project.creator_id)
        end
      end

      context 'and user contribution mapping is disabled' do
        let(:raw_data) { base_data.merge(user: octocat) }

        before do
          stub_user_mapping_chain(project, false)
        end

        it 'returns project creator_id as author_id when is not a GitLab user' do
          expect(issue.attributes.fetch(:author_id)).to eq project.creator_id
        end

        it 'returns GitLab user id associated with Gitea email as author_id' do
          gl_user = create(:user, email: octocat[:email])

          expect(issue.attributes.fetch(:author_id)).to eq gl_user.id
        end

        it 'returns description without created at tag line' do
          create(:user, email: octocat[:email])

          expect(issue.attributes.fetch(:description)).to eq("I'm having a problem with this.")
        end
      end
    end
  end

  shared_examples 'Gitlab::LegacyGithubImport::IssueFormatter#number' do
    let(:raw_data) { base_data.merge(number: 1347) }

    it 'returns issue number' do
      expect(issue.number).to eq 1347
    end
  end

  context 'when importing a Gitea project' do
    it_behaves_like 'Gitlab::LegacyGithubImport::IssueFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::IssueFormatter#number'
  end

  context 'when importing a GitHub project' do
    let_it_be(:project) do
      create(
        :project,
        :with_import_url,
        :in_group,
        :import_user_mapping_enabled,
        import_type: ::Import::SOURCE_GITHUB)
    end

    let_it_be(:source_user_mapper) do
      Gitlab::Import::SourceUserMapper.new(
        namespace: project.root_ancestor,
        import_type: project.import_type,
        source_hostname: 'https://github.com'
      )
    end

    let_it_be(:import_source_user) do
      create(
        :import_source_user,
        source_user_identifier: octocat[:id],
        namespace: project.root_ancestor,
        source_hostname: 'https://github.com',
        import_type: ::Import::SOURCE_GITHUB
      )
    end

    let(:imported_from) { ::Import::SOURCE_GITHUB }

    it_behaves_like 'Gitlab::LegacyGithubImport::IssueFormatter#attributes'
    it_behaves_like 'Gitlab::LegacyGithubImport::IssueFormatter#number'
  end

  describe '#has_comments?' do
    context 'when number of comments is greater than zero' do
      let(:raw_data) { base_data.merge(comments: 1) }

      it 'returns true' do
        expect(issue.has_comments?).to eq true
      end
    end

    context 'when number of comments is equal to zero' do
      let(:raw_data) { base_data.merge(comments: 0) }

      it 'returns false' do
        expect(issue.has_comments?).to eq false
      end
    end
  end

  describe '#pull_request?' do
    context 'when mention a pull request' do
      let(:raw_data) { base_data.merge(pull_request: double) }

      it 'returns true' do
        expect(issue.pull_request?).to eq true
      end
    end

    context 'when does not mention a pull request' do
      let(:raw_data) { base_data.merge(pull_request: nil) }

      it 'returns false' do
        expect(issue.pull_request?).to eq false
      end
    end
  end

  describe '#project_association' do
    let(:raw_data) { base_data }

    it { expect(issue.project_association).to eq(:issues) }
  end

  describe '#project_assignee_association' do
    let(:raw_data) { base_data }

    it { expect(issue.project_assignee_association).to eq(:issue_assignees) }
  end

  describe '#contributing_user_formatters' do
    let(:raw_data) { base_data }

    it 'returns a hash containing UserFormatters for user references in attributes' do
      expect(issue.contributing_user_formatters).to match(
        a_hash_including({ author_id: a_kind_of(Gitlab::LegacyGithubImport::UserFormatter) })
      )
    end

    it 'includes all user reference columns in #attributes' do
      expect(issue.contributing_user_formatters.keys).to match_array(
        issue.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.map(&:to_sym)
      )
    end
  end

  describe '#contributing_assignee_formatters' do
    let(:raw_data) { base_data.merge(assignee: octocat) }

    it 'returns a hash containing the author UserFormatter' do
      expect(issue.contributing_assignee_formatters).to match(
        a_hash_including({ user_id: a_kind_of(Gitlab::LegacyGithubImport::UserFormatter) })
      )
    end
  end

  describe '#create!', :aggregate_failures do
    let(:raw_data) { base_data.merge(assignee: octocat) }
    let(:store) { project.placeholder_reference_store }

    it 'saves the issue and assignees' do
      issue.create!
      created_issue = project.issues.find_by_iid(issue.attributes[:iid])

      expect(created_issue).not_to be_nil
      expect(created_issue&.issue_assignees).not_to be_empty
    end

    it 'pushes placeholder references for user references on the issue' do
      issue.create!
      cached_references = store.get(100).filter_map do |item|
        reference = Import::SourceUserPlaceholderReference.from_serialized(item)
        reference if reference.model == 'Issue'
      end

      expect(cached_references.map(&:model)).to eq(['Issue'])
      expect(cached_references.map(&:source_user_id)).to eq([import_source_user.id])
      expect(cached_references.map(&:user_reference_column)).to eq(['author_id'])
    end

    it 'pushes placeholder references for user references on the issue assignees' do
      issue.create!
      cached_references = store.get(100).filter_map do |item|
        reference = Import::SourceUserPlaceholderReference.from_serialized(item)
        reference if reference.model == 'IssueAssignee'
      end

      expect(cached_references.map(&:model)).to match_array(['IssueAssignee'])
      expect(cached_references.map(&:source_user_id)).to eq([import_source_user.id])
      expect(cached_references.map(&:user_reference_column)).to match_array(['user_id'])
    end

    context 'when the issue references deleted users in Gitea' do
      let(:raw_data) { base_data.merge(user: ghost_user, assignee: ghost_user) }

      it 'does not push any placeholder references' do
        issue.create!
        expect(store.empty?).to eq(true)
      end
    end

    context 'when user contribution mapping is disabled' do
      before do
        stub_user_mapping_chain(project, false)
      end

      it 'does not push any placeholder references' do
        issue.create!
        expect(store.empty?).to eq(true)
      end
    end
  end
end
