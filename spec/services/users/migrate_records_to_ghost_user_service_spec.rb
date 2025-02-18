# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::MigrateRecordsToGhostUserService, feature_category: :user_management do
  include BatchDestroyDependentAssociationsHelper

  let!(:user) { create(:user) }
  let(:service) { described_class.new(user, admin, execution_tracker) }
  let(:execution_tracker) { instance_double(::Gitlab::Utils::ExecutionTracker, over_limit?: false) }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project, :repository) }

  context "when migrating a user's associated records to the ghost user" do
    context 'for issues' do
      context 'when deleted user is present as both author and edited_user' do
        include_examples 'migrating records to the ghost user', Issue, [:author, :last_edited_by] do
          let(:created_record) do
            create(:issue, project: project, author: user, last_edited_by: user, last_edited_at: Time.current)
          end
        end
      end

      context 'when deleted user is present only as edited_user' do
        include_examples 'migrating records to the ghost user', Issue, [:last_edited_by] do
          let(:created_record) do
            create(:issue, project: project, author: create(:user), last_edited_by: user, last_edited_at: Time.current)
          end
        end
      end

      context "when deleted user is the assignee" do
        let!(:issue) { create(:issue, project: project, assignees: [user]) }

        it 'migrates the issue so that it is "Unassigned"' do
          service.execute

          migrated_issue = Issue.find_by_id(issue.id)
          expect(migrated_issue).to be_present
          expect(migrated_issue.assignees).to be_empty
        end
      end
    end

    context 'for merge requests' do
      context 'when deleted user is present as both author and merge_user' do
        include_examples 'migrating records to the ghost user', MergeRequest, [:author, :merge_user] do
          let(:created_record) do
            create(
              :merge_request,
              source_project: project,
              author: user,
              merge_user: user,
              target_branch: "first"
            )
          end
        end
      end

      context 'when deleted user is present only as both merge_user' do
        include_examples 'migrating records to the ghost user', MergeRequest, [:merge_user] do
          let(:created_record) do
            create(
              :merge_request,
              source_project: project,
              merge_user: user,
              target_branch: "first"
            )
          end
        end
      end

      context "when deleted user is the assignee" do
        let!(:merge_request) { create(:merge_request, source_project: project, assignees: [user]) }

        it 'migrates the merge request so that it is "Unassigned"' do
          service.execute

          migrated_merge_request = MergeRequest.find_by_id(merge_request.id)
          expect(migrated_merge_request).to be_present
          expect(migrated_merge_request.assignees).to be_empty
        end
      end
    end

    context 'for notes' do
      include_examples 'migrating records to the ghost user', Note do
        let(:created_record) { create(:note, project: project, author: user) }
      end
    end

    context 'for abuse reports' do
      include_examples 'migrating records to the ghost user', AbuseReport do
        let(:created_record) { create(:abuse_report, reporter: user, user: create(:user)) }
      end
    end

    context 'for award emoji' do
      include_examples 'migrating records to the ghost user', AwardEmoji, [:user] do
        let(:created_record) { create(:award_emoji, user: user) }

        context "when the awardable already has an award emoji of the same name assigned to the ghost user" do
          let(:awardable) { create(:issue) }

          let!(:existing_award_emoji) do
            create(:award_emoji, user: Users::Internal.ghost, name: AwardEmoji::THUMBS_UP, awardable: awardable)
          end

          let!(:award_emoji) { create(:award_emoji, user: user, name: AwardEmoji::THUMBS_UP, awardable: awardable) }

          it "migrates the award emoji regardless" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record.user).to eq(Users::Internal.ghost)
          end

          it "does not leave the migrated award emoji in an invalid state" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record).to be_valid
          end
        end
      end
    end

    context 'for snippets' do
      include_examples 'migrating records to the ghost user', Snippet do
        let(:created_record) { create(:project_snippet, project: project, author: user) }
      end
    end

    context 'for reviews' do
      include_examples 'migrating records to the ghost user', Review, [:author] do
        let(:created_record) { create(:review, author: user) }
      end
    end

    context 'for todos' do
      include_examples 'migrating records to the ghost user', Todo, [:author] do
        let(:issue) { create(:issue, project: project, author: user) }
        let(:created_record) do
          create(
            :todo,
            project: issue.project,
            user: create(:user),
            author: user,
            target: issue
          )
        end
      end
    end

    context 'for releases' do
      include_examples 'migrating records to the ghost user', Release, [:author] do
        let(:created_record) { create(:release, author: user) }
      end
    end

    context 'for user achievements' do
      include_examples 'migrating records to the ghost user', Achievements::UserAchievement,
        [:awarded_by_user, :revoked_by_user] do
        let(:created_record) { create(:user_achievement, awarded_by_user: user, revoked_by_user: user) }
      end
    end

    context 'when user is a bot user and has associated access tokens' do
      let_it_be(:user) { create(:user, :project_bot) }
      let_it_be(:token) { create(:personal_access_token, user: user) }

      it "deletes the access token" do
        service.execute
        expect(PersonalAccessToken.find_by(id: token.id)).to eq nil
      end
    end
  end

  context 'on post-migrate cleanups' do
    it 'destroys the user and personal namespace' do
      namespace = user.namespace

      allow(user).to receive(:destroy).and_call_original

      service.execute

      expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { Namespace.find(namespace.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'deletes user associations in batches' do
      expect(user).to receive(:destroy_dependent_associations_in_batches)

      service.execute
    end

    context 'for batched nullify' do
      # rubocop:disable Layout/LineLength
      def nullify_in_batches_regexp(table, column, user, batch_size: 100)
        if ::Gitlab.next_rails?
          %r{^UPDATE "#{table}" SET "#{column}" = NULL WHERE \("#{table}"."id"\) IN \(SELECT "#{table}"."id" FROM "#{table}" WHERE "#{table}"."#{column}" = #{user.id} LIMIT #{batch_size}\)}
        else
          %r{^UPDATE "#{table}" SET "#{column}" = NULL WHERE "#{table}"."id" IN \(SELECT "#{table}"."id" FROM "#{table}" WHERE "#{table}"."#{column}" = #{user.id} LIMIT #{batch_size}\)}
        end
      end
      # rubocop:enable Layout/LineLength

      it 'nullifies related associations in batches' do
        expect(user).to receive(:nullify_dependent_associations_in_batches).and_call_original

        service.execute
      end

      it 'nullifies associations marked as `dependent: :nullify` and'\
         'destroys the associations marked as `dependent: :destroy`, in batches', :aggregate_failures do
        # associations to be nullified
        issue = create(:issue, closed_by: user, updated_by: user)
        resource_label_event = create(:resource_label_event, user: user)
        resource_state_event = create(:resource_state_event, user: user)
        created_project = create(:project, creator: user)

        # associations to be destroyed
        todos = create_list(:todo, 2, project: issue.project, user: user, author: create(:user), target: issue)
        event = create(:event, project: issue.project, author: user)

        query_recorder = ActiveRecord::QueryRecorder.new do
          service.execute
        end

        issue.reload
        resource_label_event.reload
        resource_state_event.reload
        created_project.reload

        expect(issue.closed_by).to be_nil
        expect(issue.updated_by_id).to be_nil
        expect(resource_label_event.user_id).to be_nil
        expect(resource_state_event.user_id).to be_nil
        expect(created_project.creator_id).to be_nil
        expect(user.todos).to be_empty
        expect(user.authored_events).to be_empty

        expected_queries = [
          nullify_in_batches_regexp(:issues, :updated_by_id, user),
          nullify_in_batches_regexp(:issues, :closed_by_id, user),
          nullify_in_batches_regexp(:resource_label_events, :user_id, user),
          nullify_in_batches_regexp(:resource_state_events, :user_id, user),
          nullify_in_batches_regexp(:projects, :creator_id, user)
        ]

        expected_queries += delete_in_batches_regexps(:todos, :user_id, user, todos)
        expected_queries += delete_in_batches_regexps(:events, :author_id, user, [event])

        expect(query_recorder.log).to include(*expected_queries)
      end

      it 'nullifies merge request associations', :aggregate_failures do
        merge_request = create(
          :merge_request,
          source_project: project,
          target_project: project,
          assignee: user,
          updated_by: user,
          merge_user: user
        )
        merge_request.metrics.update!(merged_by: user, latest_closed_by: user)
        merge_request.reviewers = [user]
        merge_request.assignees = [user]

        query_recorder = ActiveRecord::QueryRecorder.new do
          service.execute
        end

        merge_request.reload

        expect(merge_request.updated_by).to be_nil
        expect(merge_request.assignee).to be_nil
        expect(merge_request.assignee_id).to be_nil
        expect(merge_request.metrics.merged_by).to be_nil
        expect(merge_request.metrics.latest_closed_by).to be_nil
        expect(merge_request.reviewers).to be_empty
        expect(merge_request.assignees).to be_empty

        expected_queries = [
          nullify_in_batches_regexp(:merge_requests, :updated_by_id, user),
          nullify_in_batches_regexp(:merge_requests, :assignee_id, user),
          nullify_in_batches_regexp(:merge_request_metrics, :merged_by_id, user),
          nullify_in_batches_regexp(:merge_request_metrics, :latest_closed_by_id, user)
        ]

        expected_queries += delete_in_batches_regexps(
          :merge_request_assignees,
          :user_id,
          user,
          merge_request.assignees
        )
        expected_queries += delete_in_batches_regexps(
          :merge_request_reviewers,
          :user_id,
          user,
          merge_request.reviewers
        )

        expect(query_recorder.log).to include(*expected_queries)
      end
    end

    context 'for snippets' do
      let(:gitlab_shell) { Gitlab::Shell.new }

      it 'does not include snippets when deleting in batches' do
        expect(user).to receive(:destroy_dependent_associations_in_batches).with({ exclude: [:snippets] })

        service.execute
      end

      it 'calls the bulk snippet destroy service for the user personal snippets' do
        repo1 = create(:personal_snippet, :repository, author: user).snippet_repository
        repo2 = create(:project_snippet, :repository, project: project, author: user).snippet_repository

        aggregate_failures do
          expect(gitlab_shell.repository_exists?(repo1.shard_name, "#{repo1.disk_path}.git")).to be(true)
          expect(gitlab_shell.repository_exists?(repo2.shard_name, "#{repo2.disk_path}.git")).to be(true)
        end

        # Call made when destroying user personal projects
        expect(Snippets::BulkDestroyService).not_to(
          receive(:new).with(admin, project.snippets).and_call_original)

        # Call to remove user personal snippets and for
        # project snippets where projects are not user personal
        # ones
        expect(Snippets::BulkDestroyService).to(
          receive(:new).with(admin, user.snippets.only_personal_snippets).and_call_original)

        service.execute

        aggregate_failures do
          expect(gitlab_shell.repository_exists?(repo1.shard_name, "#{repo1.disk_path}.git")).to be(false)
          expect(gitlab_shell.repository_exists?(repo2.shard_name, "#{repo2.disk_path}.git")).to be(true)
        end
      end

      it 'calls the bulk snippet destroy service with hard delete option if it is present' do
        # this avoids getting into Projects::DestroyService as it would
        # call Snippets::BulkDestroyService first!
        allow(user).to receive(:personal_projects).and_return([])

        expect_next_instance_of(Snippets::BulkDestroyService) do |bulk_destroy_service|
          expect(bulk_destroy_service).to receive(:execute).with({ skip_authorization: true }).and_call_original
        end

        service.execute(hard_delete: true)
      end

      it 'does not delete project snippets that the user is the author of' do
        repo = create(:project_snippet, :repository, author: user).snippet_repository

        service.execute

        expect(gitlab_shell.repository_exists?(repo.shard_name, "#{repo.disk_path}.git")).to be(true)
        expect(Users::Internal.ghost.snippets).to include(repo.snippet)
      end

      context 'when an error is raised deleting snippets' do
        it 'does not delete user' do
          snippet = create(:personal_snippet, :repository, author: user)

          bulk_service = double
          allow(Snippets::BulkDestroyService).to receive(:new).and_call_original
          allow(Snippets::BulkDestroyService).to receive(:new).with(admin, user.snippets).and_return(bulk_service)
          allow(bulk_service).to receive(:execute).and_return(ServiceResponse.error(message: 'foo'))

          aggregate_failures do
            expect { service.execute }.to(
              raise_error(Users::MigrateRecordsToGhostUserService::DestroyError, 'foo'))
            expect(snippet.reload).not_to be_nil
            expect(
              gitlab_shell.repository_exists?(snippet.repository_storage, "#{snippet.disk_path}.git")
            ).to be(true)
          end
        end
      end
    end

    context 'when hard_delete option is given' do
      it 'will not ghost certain records' do
        issue = create(:issue, author: user)

        service.execute(hard_delete: true)

        expect(Issue).not_to exist(issue.id)
      end

      it 'migrates awarded and revoked fields of user achievements' do
        user_achievement = create(:user_achievement, awarded_by_user: user, revoked_by_user: user)

        service.execute(hard_delete: true)
        user_achievement.reload

        expect(user_achievement.revoked_by_user).to eq(Users::Internal.ghost)
        expect(user_achievement.awarded_by_user).to eq(Users::Internal.ghost)
      end
    end
  end
end
