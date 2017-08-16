require 'spec_helper'

describe Users::MigrateToGhostUserService do
  let!(:user)      { create(:user) }
  let!(:project)   { create(:project, :repository) }
  let(:service)    { described_class.new(user) }

  context "migrating a user's associated records to the ghost user" do
    context 'issues'  do
      context 'deleted user is present as both author and edited_user' do
        include_examples "migrating a deleted user's associated records to the ghost user", Issue, [:author, :last_edited_by] do
          let(:created_record) do
            create(:issue, project: project, author: user, last_edited_by: user)
          end
        end
      end

      context 'deleted user is present only as edited_user' do
        include_examples "migrating a deleted user's associated records to the ghost user", Issue, [:last_edited_by] do
          let(:created_record) { create(:issue, project: project, author: create(:user), last_edited_by: user) }
        end
      end
    end

    context 'merge requests' do
      context 'deleted user is present as both author and merge_user' do
        include_examples "migrating a deleted user's associated records to the ghost user", MergeRequest, [:author, :merge_user] do
          let(:created_record) { create(:merge_request, source_project: project, author: user, merge_user: user, target_branch: "first") }
        end
      end

      context 'deleted user is present only as both merge_user' do
        include_examples "migrating a deleted user's associated records to the ghost user", MergeRequest, [:merge_user] do
          let(:created_record) { create(:merge_request, source_project: project, merge_user: user, target_branch: "first") }
        end
      end
    end

    context 'notes' do
      include_examples "migrating a deleted user's associated records to the ghost user", Note do
        let(:created_record) { create(:note, project: project, author: user) }
      end
    end

    context 'abuse reports' do
      include_examples "migrating a deleted user's associated records to the ghost user", AbuseReport do
        let(:created_record) { create(:abuse_report, reporter: user, user: create(:user)) }
      end
    end

    context 'award emoji' do
      include_examples "migrating a deleted user's associated records to the ghost user", AwardEmoji, [:user] do
        let(:created_record) { create(:award_emoji, user: user) }

        context "when the awardable already has an award emoji of the same name assigned to the ghost user" do
          let(:awardable) { create(:issue) }
          let!(:existing_award_emoji) { create(:award_emoji, user: User.ghost, name: "thumbsup", awardable: awardable) }
          let!(:award_emoji) { create(:award_emoji, user: user, name: "thumbsup", awardable: awardable) }

          it "migrates the award emoji regardless" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record.user).to eq(User.ghost)
          end

          it "does not leave the migrated award emoji in an invalid state" do
            service.execute

            migrated_record = AwardEmoji.find_by_id(award_emoji.id)

            expect(migrated_record).to be_valid
          end
        end
      end
    end

    context "when record migration fails with a rollback exception" do
      before do
        expect_any_instance_of(MergeRequest::ActiveRecord_Associations_CollectionProxy)
          .to receive(:update_all).and_raise(ActiveRecord::Rollback)
      end

      context "for records that were already migrated" do
        let!(:issue) { create(:issue, project: project, author: user) }
        let!(:merge_request) { create(:merge_request, source_project: project, author: user, target_branch: "first") }

        it "reverses the migration" do
          service.execute

          expect(issue.reload.author).to eq(user)
        end
      end
    end
  end
end
