require 'spec_helper'

describe Users::DestroyService, services: true do
  describe "Deletes a user and all their personal projects" do
    let!(:user)      { create(:user) }
    let!(:admin)     { create(:admin) }
    let!(:namespace) { create(:namespace, owner: user) }
    let!(:project)   { create(:empty_project, namespace: namespace) }
    let(:service)    { described_class.new(admin) }

    context 'no options are given' do
      it 'deletes the user' do
        user_data = service.execute(user)

        expect { user_data['email'].to eq(user.email) }
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
        expect { Namespace.with_deleted.find(user.namespace.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'will delete the project' do
        expect_any_instance_of(Projects::DestroyService).to receive(:execute).once

        service.execute(user)
      end
    end

    context 'projects in pending_delete' do
      before do
        project.pending_delete = true
        project.save
      end

      it 'destroys a project in pending_delete' do
        expect_any_instance_of(Projects::DestroyService).to receive(:execute).once

        service.execute(user)

        expect { Project.find(project.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "a deleted user's issues" do
      let(:project) { create(:project) }

      before do
        project.add_developer(user)
      end

      context "for an issue the user has created" do
        let!(:issue) { create(:issue, project: project, author: user) }

        before do
          service.execute(user)
        end

        it 'does not delete the issue' do
          expect(Issue.find_by_id(issue.id)).to be_present
        end

        it 'migrates the issue so that the "Ghost User" is the issue owner' do
          migrated_issue = Issue.find_by_id(issue.id)

          expect(migrated_issue.author).to eq(User.ghost)
        end

        it 'blocks the user before migrating issues to the "Ghost User' do
          expect(user).to be_blocked
        end
      end

      context "for an issue the user was assigned to" do
        let!(:issue) { create(:issue, project: project, assignee: user) }

        before do
          service.execute(user)
        end

        it 'does not delete issues the user is assigned to' do
          expect(Issue.find_by_id(issue.id)).to be_present
        end

        it 'migrates the issue so that it is "Unassigned"' do
          migrated_issue = Issue.find_by_id(issue.id)

          expect(migrated_issue.assignee).to be_nil
        end
      end
    end

    context "solo owned groups present" do
      let(:solo_owned)  { create(:group) }
      let(:member)      { create(:group_member) }
      let(:user)        { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user)
      end

      it 'does not delete the user' do
        expect(User.find(user.id)).to eq user
      end
    end

    context "deletions with solo owned groups" do
      let(:solo_owned)      { create(:group) }
      let(:member)          { create(:group_member) }
      let(:user)            { member.user }

      before do
        solo_owned.group_members = [member]
        service.execute(user, delete_solo_owned_groups: true)
      end

      it 'deletes solo owned groups' do
        expect { Project.find(solo_owned.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it 'deletes the user' do
        expect { User.find(user.id) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "deletion permission checks" do
      it 'does not delete the user when user is not an admin' do
        other_user = create(:user)

        expect { described_class.new(other_user).execute(user) }.to raise_error(Gitlab::Access::AccessDeniedError)
        expect(User.exists?(user.id)).to be(true)
      end

      it 'allows admins to delete anyone' do
        described_class.new(admin).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end

      it 'allows users to delete their own account' do
        described_class.new(user).execute(user)

        expect(User.exists?(user.id)).to be(false)
      end
    end

    context 'migrating associated records to the ghost user' do
      context 'issues'  do
        include_examples "migrating a deleted user's associated records to the ghost user", Issue, {} do
          let(:created_record) { create(:issue, project: project, author: user) }
          let(:assigned_record) { create(:issue, project: project, assignee: user) }
        end
      end

      context 'merge requests' do
        include_examples "migrating a deleted user's associated records to the ghost user", MergeRequest, {} do
          let(:created_record) { create(:merge_request, source_project: project, author: user, target_branch: "first") }
          let(:assigned_record) { create(:merge_request, source_project: project, assignee: user, target_branch: 'second') }
        end
      end

      context 'notes' do
        include_examples "migrating a deleted user's associated records to the ghost user", Note, { skip_assignee_specs: true } do
          let(:created_record) { create(:note, project: project, author: user) }
        end
      end

      context 'abuse reports' do
        include_examples "migrating a deleted user's associated records to the ghost user", AbuseReport, { skip_assignee_specs: true } do
          let(:created_record) { create(:abuse_report, reporter: user, user: create(:user)) }
        end
      end

      context 'award emoji' do
        include_examples "migrating a deleted user's associated records to the ghost user", AwardEmoji, { skip_assignee_specs: true } do
          let(:created_record) { create(:award_emoji, user: user) }
          let(:author_alias) { :user }

          context "when the awardable already has an award emoji of the same name assigned to the ghost user" do
            let(:awardable) { create(:issue) }
            let!(:existing_award_emoji) { create(:award_emoji, user: User.ghost, name: "thumbsup", awardable: awardable) }
            let!(:award_emoji) { create(:award_emoji, user: user, name: "thumbsup", awardable: awardable) }

            it "migrates the award emoji regardless" do
              service.execute(user)

              migrated_record = AwardEmoji.find_by_id(award_emoji.id)

              expect(migrated_record.user).to eq(User.ghost)
            end

            it "does not leave the migrated award emoji in an invalid state" do
              service.execute(user)

              migrated_record = AwardEmoji.find_by_id(award_emoji.id)

              expect(migrated_record).to be_valid
            end
          end
        end
      end
    end
  end
end
