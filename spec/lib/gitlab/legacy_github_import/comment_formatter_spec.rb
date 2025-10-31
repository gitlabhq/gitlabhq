# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::LegacyGithubImport::CommentFormatter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  include Import::UserMappingHelper

  let_it_be_with_reload(:project) do
    create(
      :project, :in_group, :with_import_url,
      :import_user_mapping_enabled, :user_mapping_to_personal_namespace_owner_enabled,
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let_it_be(:octocat) { { id: 1234, login: 'octocat', full_name: 'Cat', email: 'octocat@example.com' } }
  let_it_be(:import_source_user) do
    create(
      :import_source_user,
      source_user_identifier: octocat[:id],
      namespace: project.root_ancestor,
      source_hostname: 'https://gitea.com',
      import_type: ::Import::SOURCE_GITEA
    )
  end

  let(:source_user_mapper) do
    Gitlab::Import::SourceUserMapper.new(
      namespace: project.root_ancestor,
      import_type: project.import_type,
      source_hostname: 'https://gitea.com'
    )
  end

  let(:client) { instance_double(Gitlab::LegacyGithubImport::Client) }
  let(:ghost_user) { { id: -1, login: 'Ghost' } }
  let(:created_at) { DateTime.strptime('2013-04-10T20:09:31Z') }
  let(:updated_at) { DateTime.strptime('2014-03-03T18:58:10Z') }
  let(:imported_from) { ::Import::SOURCE_GITEA }
  let(:base) do
    {
      body: "I'm having a problem with this.",
      user: octocat,
      commit_id: nil,
      diff_hunk: nil,
      created_at: created_at,
      updated_at: updated_at,
      imported_from: imported_from
    }
  end

  subject(:comment) { described_class.new(project, raw, client, source_user_mapper) }

  before do
    allow(client).to receive(:user).and_return(octocat)
  end

  describe '#attributes' do
    context 'when the note author exists on the source' do
      let(:raw) { base }

      it 'sets the note author to a placeholder user' do
        expect(comment.attributes.fetch(:author_id)).to eq(import_source_user.placeholder_user_id)
      end

      it 'returns note without created at tag line' do
        expect(comment.attributes.fetch(:note)).to eq("I'm having a problem with this.")
      end
    end

    context 'when the note author has been deleted from Gitea' do
      let(:ghost_user) { { id: -1, login: 'Ghost', email: 'ghost_user@gitea_import_dummy_email.com' } }
      let(:raw) { base.merge(user: ghost_user) }

      it 'sets the note author as the gitlab ghost user' do
        expect(comment.attributes.fetch(:author_id)).to eq(
          Users::Internal.for_organization(project.organization).ghost.id
        )
      end
    end

    context 'when do not reference a portion of the diff' do
      let(:raw) { base }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "I'm having a problem with this.",
          commit_id: nil,
          line_code: nil,
          author_id: import_source_user.placeholder_user_id,
          type: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when on a portion of the diff' do
      let(:diff) do
        {
          body: 'Great stuff',
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          diff_hunk: "@@ -1,5 +1,9 @@\n class User\n   def name\n-    'John Doe'\n+    'Jane Doe'",
          path: 'file1.txt'
        }
      end

      let(:raw) { base.merge(diff) }

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "Great stuff",
          commit_id: '6dcb09b5b57875f334f61aebed695e2e4193db5e',
          line_code: 'ce1be0ff4065a6e9415095c95f25f47a633cef2b_4_3',
          author_id: import_source_user.placeholder_user_id,
          type: 'LegacyDiffNote',
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when the comment body has @username mentions' do
      let(:original_body) { "I said to @sam_allen.greg the code should follow @bob's advice. @.ali-ce/group#9?" }
      let(:expected_body) { "I said to `@sam_allen.greg` the code should follow `@bob`'s advice. `@.ali-ce/group#9`?" }
      let(:raw) { base.merge(body: original_body) }

      it 'places backtick around @username mentions' do
        expect(comment.attributes[:note]).to eq(expected_body)
      end
    end

    context 'when importing a GitHub project' do
      let_it_be(:project) do
        create(:project, :with_import_url, :import_user_mapping_enabled, import_type: ::Import::SOURCE_GITHUB)
      end

      let_it_be(:source_user_mapper) do
        Gitlab::Import::SourceUserMapper.new(
          namespace: project.root_ancestor,
          import_type: project.import_type,
          source_hostname: 'https://github.com'
        )
      end

      let(:imported_from) { ::Import::SOURCE_GITHUB }
      let(:raw) { base }
      let!(:import_source_user) do
        create(
          :import_source_user,
          source_user_identifier: octocat[:id],
          namespace: project.root_ancestor,
          source_hostname: 'https://github.com',
          import_type: imported_from
        )
      end

      it 'returns formatted attributes' do
        expected = {
          project: project,
          note: "I'm having a problem with this.",
          commit_id: nil,
          line_code: nil,
          author_id: import_source_user.placeholder_user_id,
          type: nil,
          created_at: created_at,
          updated_at: updated_at,
          imported_from: imported_from
        }

        expect(comment.attributes).to eq(expected)
      end
    end

    context 'when a gitlab issuable record is assigned' do
      let(:raw) { base }
      let(:issuable) { create(:issue, project: project) }

      it 'saves the comment to the issuable' do
        comment.gitlab_issuable = issuable

        expect { comment.create! }.to change { issuable.notes.count }.from(0).to(1)
      end
    end

    context 'when importing into a personal namespace' do
      let_it_be(:user_namespace) { create(:namespace) }
      let(:raw) { base }

      before_all do
        project.update!(namespace: user_namespace)
      end

      it 'maps the author to the personal namespace owner' do
        expect(comment.attributes.fetch(:author_id)).to eq(user_namespace.owner_id)
      end

      context 'when user_mapping_to_personal_namespace_owner is disabled' do
        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'maps the author to the import user' do
          expect(comment.attributes.fetch(:author_id)).to eq(
            user_namespace.namespace_import_user.user_id
          )
        end
      end
    end

    context 'when user contribution mapping is disabled' do
      let(:raw) { base.merge(user: octocat) }

      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      context 'when author is a GitLab user' do
        let_it_be(:gitlab_user) { create(:user, email: octocat[:email]) }

        it 'returns GitLab user id associated with GitHub email as author_id' do
          expect(comment.attributes.fetch(:author_id)).to eq(gitlab_user.id)
        end

        it 'returns note without created at tag line' do
          expect(comment.attributes.fetch(:note)).to eq("I'm having a problem with this.")
        end
      end

      context 'when the author does not exist in gitlab' do
        it 'sets the note author as the project creator' do
          expect(comment.attributes.fetch(:author_id)).to eq(project.creator_id)
        end

        it 'returns note with "Created by:" tag line' do
          expect(comment.attributes.fetch(:note)).to eq("*Created by: octocat*\n\nI'm having a problem with this.")
        end

        it 'does not create a placeholder user' do
          expect { comment }.not_to change { User.where(user_type: :placeholder).count }
        end
      end
    end
  end

  describe '#project_association' do
    let(:raw) { base }

    it { expect(comment.project_association).to eq(:notes) }
  end

  describe '#contributing_user_formatters' do
    let(:raw) { base }

    it 'returns a hash containing UserFormatters for user references in attributes' do
      expect(comment.contributing_user_formatters).to match(
        a_hash_including({ author_id: a_kind_of(Gitlab::LegacyGithubImport::UserFormatter) })
      )
    end

    it 'includes all user reference columns in #attributes' do
      expect(comment.contributing_user_formatters.keys).to match_array(
        comment.attributes.keys & Gitlab::ImportExport::Base::RelationFactory::USER_REFERENCES.map(&:to_sym)
      )
    end
  end

  describe '#create!', :aggregate_failures do
    let(:issuable) { create(:issue, project: project) }
    let(:raw) { base }
    let(:cached_references) { placeholder_user_references(Import::SOURCE_GITEA, project.import_state.id) }

    before do
      comment.gitlab_issuable = issuable
    end

    it 'saves the comment' do
      expect { comment.create! }.to change { issuable.notes.count }.from(0).to(1)
    end

    it 'pushes placeholder references for comments made by existing users in Gitea' do
      comment.create!

      expect(cached_references).to match_array([
        ['Note', an_instance_of(Integer), 'author_id', import_source_user.id]
      ])
    end

    context 'when the comment was made by a deleted user in Gitea' do
      let(:raw) { base.merge(user: ghost_user) }

      it 'does not push any placeholder references' do
        comment.create!
        expect(cached_references).to be_empty
      end
    end

    context 'when importing into a personal namespace' do
      before_all do
        project.update!(namespace: create(:namespace))
      end

      it 'does not push any placeholder references' do
        comment.create!
        expect(cached_references).to be_empty
      end

      context 'when user_mapping_to_personal_namespace_owner is disabled' do
        before_all do
          project.build_or_assign_import_data(
            data: { user_mapping_to_personal_namespace_owner_enabled: false }
          ).save!
        end

        it 'pushes placeholder references for the pull request and assignees' do
          comment.create!

          import_source_user = Import::SourceUser.find_source_user(
            source_user_identifier: octocat[:id],
            namespace: project.root_ancestor,
            source_hostname: 'https://gitea.com',
            import_type: ::Import::SOURCE_GITEA
          )

          expect(cached_references).to match_array([
            ['Note', an_instance_of(Integer), 'author_id', import_source_user.id]
          ])
        end
      end
    end

    context 'when user contribution mapping is disabled' do
      before do
        project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
      end

      it 'does not push any placeholder references' do
        comment.create!
        expect(cached_references).to be_empty
      end
    end
  end
end
