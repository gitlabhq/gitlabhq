# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'cloning and repointing with a null commit user field' do |null_field|
  let_it_be(:null_field_user) do
    attrs = { organization_id: old_organization.id, name: 'Author With Null Field',
              email: 'author-null-field@example.com' }
    attrs[null_field] = nil
    create(:merge_request_diff_commit_user, **attrs)
  end

  let_it_be(:null_field_project) { create(:project, namespace: group, organization: old_organization) }
  let_it_be(:null_field_mr) do
    create(:merge_request, source_project: null_field_project, target_project: null_field_project)
  end

  let_it_be(:null_field_diff) { create(:merge_request_diff, merge_request: null_field_mr) }
  let_it_be(:null_field_diff_commit) do
    create(:merge_request_diff_commit,
      merge_request_diff: null_field_diff,
      commit_author: null_field_user,
      committer: null_field_user
    )
  end

  context 'when a second batch also tries to clone the same user' do
    let_it_be(:second_null_field_project) { create(:project, namespace: group, organization: old_organization) }
    let_it_be(:second_null_field_mr) do
      create(:merge_request, source_project: second_null_field_project, target_project: second_null_field_project)
    end

    let_it_be(:second_null_field_diff) do
      create(:merge_request_diff, merge_request: second_null_field_mr)
    end

    let_it_be(:second_null_field_diff_commit) do
      create(:merge_request_diff_commit,
        merge_request_diff: second_null_field_diff,
        commit_author: null_field_user,
        committer: null_field_user
      )
    end

    before do
      stub_const("#{described_class}::BATCH_SIZE", 1)
    end

    it 'does not create a duplicate clone' do
      execute

      clones_count = MergeRequest::DiffCommitUser.where(
        organization_id: new_organization.id,
        name: null_field_user.name,
        email: null_field_user.email
      ).count

      expect(clones_count).to eq(1)
    end

    it 'repoints all commit_metadata rows to the single clone' do
      execute

      cloned_user = MergeRequest::DiffCommitUser.find_by!(
        organization_id: new_organization.id,
        name: null_field_user.name,
        email: null_field_user.email
      )
      first_metadata = metadata_for(null_field_diff_commit)
      second_metadata = metadata_for(second_null_field_diff_commit)

      expect(first_metadata.commit_author_id).to eq(cloned_user.id)
      expect(second_metadata.commit_author_id).to eq(cloned_user.id)
    end
  end
end

RSpec.describe Organizations::DataSeverance::MergeRequestDiffCommitUsersService,
  :aggregate_failures, feature_category: :code_review_workflow do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }
  let_it_be(:group) { create(:group, organization: old_organization) }
  let_it_be(:subgroup) { create(:group, parent: group, organization: old_organization) }
  let_it_be(:project) { create(:project, namespace: group, organization: old_organization) }

  subject(:execute) do
    described_class.new(
      group: group,
      old_organization: old_organization,
      new_organization: new_organization
    ).execute
  end

  describe '#execute' do
    context 'when there are no merge_request_diff_commit_users in old_organization' do
      it 'returns without error' do
        expect { execute }.not_to raise_error
      end

      it 'does not create any commit users in new_organization' do
        expect { execute }.not_to change {
          MergeRequest::DiffCommitUser.where(organization_id: new_organization.id).count
        }
      end
    end

    context 'when a block is given' do
      let_it_be(:second_project) { create(:project, namespace: subgroup, organization: old_organization) }

      it 'yields the id of each processed project in order' do
        service = described_class.new(
          group: group,
          old_organization: old_organization,
          new_organization: new_organization
        )

        expect { |b| service.execute(&b) }.to yield_successive_args(project.id, second_project.id)
      end
    end

    context 'when there are merge_request_diff_commit_users in old_organization' do
      let_it_be(:commit_author) do
        create(:merge_request_diff_commit_user, organization_id: old_organization.id)
      end

      let_it_be(:committer) do
        create(:merge_request_diff_commit_user, organization_id: old_organization.id)
      end

      let_it_be(:merge_request) do
        create(:merge_request, source_project: project, target_project: project)
      end

      let_it_be(:merge_request_diff) do
        create(:merge_request_diff, merge_request: merge_request)
      end

      let_it_be(:diff_commit) do
        create(:merge_request_diff_commit,
          merge_request_diff: merge_request_diff,
          commit_author: commit_author,
          committer: committer
        )
      end

      # MergeRequestDiffCommit uses a composite PK; look up metadata directly via its ID
      def metadata_for(diff_commit_record)
        MergeRequest::CommitsMetadata.find(diff_commit_record.merge_request_commits_metadata_id)
      end

      # Re-fetch a MergeRequestDiffCommit row by its composite PK columns
      def refind_diff_commit(diff_commit_record)
        MergeRequestDiffCommit.find_by(
          merge_request_diff_id: diff_commit_record.merge_request_diff_id,
          relative_order: diff_commit_record.relative_order
        )
      end

      it 'creates equivalent commit users in the new organization' do
        execute

        new_author = MergeRequest::DiffCommitUser.find_by(
          organization_id: new_organization.id,
          name: commit_author.name,
          email: commit_author.email
        )
        new_committer_user = MergeRequest::DiffCommitUser.find_by(
          organization_id: new_organization.id,
          name: committer.name,
          email: committer.email
        )

        expect(new_author).to be_present
        expect(new_committer_user).to be_present
      end

      it 'updates commit_author_id and committer_id on merge_request_commits_metadata' do
        execute

        new_author = MergeRequest::DiffCommitUser.find_by!(
          organization_id: new_organization.id,
          name: commit_author.name
        )
        new_committer_user = MergeRequest::DiffCommitUser.find_by!(
          organization_id: new_organization.id,
          name: committer.name
        )

        metadata = metadata_for(diff_commit)

        expect(metadata.commit_author_id).to eq(new_author.id)
        expect(metadata.committer_id).to eq(new_committer_user.id)
      end

      context 'with projects in subgroups' do
        let_it_be(:subgroup_project) { create(:project, namespace: subgroup, organization: old_organization) }
        let_it_be(:subgroup_merge_request) do
          create(:merge_request, source_project: subgroup_project, target_project: subgroup_project)
        end

        let_it_be(:subgroup_diff) do
          create(:merge_request_diff, merge_request: subgroup_merge_request)
        end

        let_it_be(:subgroup_diff_commit) do
          create(:merge_request_diff_commit,
            merge_request_diff: subgroup_diff,
            commit_author: commit_author,
            committer: committer
          )
        end

        it 'updates commit metadata for projects in subgroups' do
          execute

          new_author = MergeRequest::DiffCommitUser.find_by!(
            organization_id: new_organization.id,
            name: commit_author.name
          )

          subgroup_metadata = metadata_for(subgroup_diff_commit)
          expect(subgroup_metadata.commit_author_id).to eq(new_author.id)
        end
      end

      context 'when commit users already exist in new_organization' do
        before do
          MergeRequest::DiffCommitUser.find_or_create(
            commit_author.name, commit_author.email, new_organization.id
          )
          MergeRequest::DiffCommitUser.find_or_create(
            committer.name, committer.email, new_organization.id
          )
        end

        it 'does not create duplicate commit users' do
          expect { execute }.not_to change {
            MergeRequest::DiffCommitUser.where(organization_id: new_organization.id).count
          }
        end

        it 'still updates commit references to point to the existing new_organization rows' do
          execute

          new_author = MergeRequest::DiffCommitUser.find_by!(
            organization_id: new_organization.id,
            name: commit_author.name
          )

          metadata = metadata_for(diff_commit)
          expect(metadata.commit_author_id).to eq(new_author.id)
        end
      end

      context 'when the number of commits_metadata entries exceeds BATCH_SIZE' do
        let_it_be(:second_diff_commit) do
          create(:merge_request_diff_commit,
            merge_request_diff: create(:merge_request_diff, merge_request: merge_request),
            commit_author: commit_author,
            committer: committer
          )
        end

        before do
          stub_const("#{described_class}::BATCH_SIZE", 1)
        end

        it 'updates all commit references correctly across multiple commits_metadata batches' do
          execute

          new_author = MergeRequest::DiffCommitUser.find_by!(
            organization_id: new_organization.id,
            name: commit_author.name
          )
          new_committer_user = MergeRequest::DiffCommitUser.find_by!(
            organization_id: new_organization.id,
            name: committer.name
          )

          metadata = metadata_for(diff_commit)
          second_metadata = metadata_for(second_diff_commit)

          expect(metadata.commit_author_id).to eq(new_author.id)
          expect(metadata.committer_id).to eq(new_committer_user.id)
          expect(second_metadata.commit_author_id).to eq(new_author.id)
          expect(second_metadata.committer_id).to eq(new_committer_user.id)
        end
      end

      context 'when a cursor is provided' do
        let_it_be(:second_project) { create(:project, namespace: group, organization: old_organization) }
        let_it_be(:second_mr) do
          create(:merge_request, source_project: second_project, target_project: second_project)
        end

        let_it_be(:second_diff) { create(:merge_request_diff, merge_request: second_mr) }
        let_it_be(:second_diff_commit) do
          create(:merge_request_diff_commit,
            merge_request_diff: second_diff,
            commit_author: commit_author,
            committer: committer
          )
        end

        it 'skips projects up to and including the cursor and only processes later ones' do
          described_class.new(
            group: group,
            old_organization: old_organization,
            new_organization: new_organization
          ).execute(cursor: project.id)

          new_author = MergeRequest::DiffCommitUser.find_by!(
            organization_id: new_organization.id,
            name: commit_author.name
          )

          first_metadata = metadata_for(diff_commit)
          second_metadata = metadata_for(second_diff_commit)

          expect(first_metadata.commit_author_id).to eq(commit_author.id)
          expect(second_metadata.commit_author_id).to eq(new_author.id)
        end
      end

      context 'when a merge request belongs to a project outside the transferred group' do
        let_it_be(:other_group) { create(:group, organization: old_organization) }
        let_it_be(:other_project) { create(:project, namespace: other_group, organization: old_organization) }
        let_it_be(:other_mr) do
          create(:merge_request, source_project: other_project, target_project: other_project)
        end

        let_it_be(:other_diff) { create(:merge_request_diff, merge_request: other_mr) }
        let_it_be(:other_diff_commit) do
          create(:merge_request_diff_commit,
            merge_request_diff: other_diff,
            commit_author: commit_author,
            committer: committer
          )
        end

        it 'does not update commit metadata for projects outside the transferred group' do
          original_author_id = metadata_for(other_diff_commit).commit_author_id

          execute

          expect(metadata_for(other_diff_commit).commit_author_id).to eq(original_author_id)
        end
      end

      it_behaves_like 'cloning and repointing with a null commit user field', :email
      it_behaves_like 'cloning and repointing with a null commit user field', :name
    end
  end
end
