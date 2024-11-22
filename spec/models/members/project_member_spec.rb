# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectMember, feature_category: :groups_and_projects do
  describe 'associations' do
    it { is_expected.to belong_to(:project).with_foreign_key(:source_id) }
  end

  describe 'validations' do
    it { is_expected.to allow_value('Project').for(:source_type) }
    it { is_expected.not_to allow_value('Group').for(:source_type) }
    it { is_expected.to validate_inclusion_of(:access_level).in_array(Gitlab::Access.values) }
  end

  describe 'default values' do
    it { expect(described_class.new.source_type).to eq('Project') }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:namespace_id).to(:project) }
  end

  describe '.access_level_roles' do
    it 'returns Gitlab::Access.options' do
      expect(described_class.access_level_roles).to eq(Gitlab::Access.options)
    end
  end

  describe '#permissible_access_level_roles' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    before do
      project.add_owner(owner)
      project.add_maintainer(maintainer)
    end

    context 'when member can manage owners' do
      it 'returns Gitlab::Access.options_with_owner' do
        expect(described_class.permissible_access_level_roles(owner, project)).to eq(Gitlab::Access.options_with_owner)
      end
    end

    context 'when member cannot manage owners' do
      it 'returns Gitlab::Access.options' do
        expect(described_class.permissible_access_level_roles(maintainer, project)).to eq(Gitlab::Access.options)
      end
    end
  end

  describe '.permissible_access_level_roles_for_project_access_token' do
    let_it_be(:owner) { create(:user) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:admin) { create(:admin) }

    before do
      project.add_owner(owner)
      project.add_maintainer(maintainer)
      project.add_developer(developer)
    end

    subject(:access_levels) { described_class.permissible_access_level_roles_for_project_access_token(user, project) }

    context 'when member can manage owners' do
      let(:user) { owner }

      it 'returns Gitlab::Access.options_with_owner' do
        expect(access_levels).to eq(Gitlab::Access.options_with_owner)
      end
    end

    context 'when member can manage owners via admin' do
      let(:user) { admin }

      context 'with admin mode', :enable_admin_mode do
        it 'returns Gitlab::Access.options_with_owner' do
          expect(access_levels).to eq(Gitlab::Access.options_with_owner)
        end
      end

      context 'without admin mode' do
        it 'returns empty hash' do
          expect(access_levels).to eq({})
        end
      end
    end

    context 'when user is not a project member' do
      let(:user) { create(:user) }

      it 'return an empty hash' do
        expect(access_levels).to eq({})
      end
    end

    context 'when member cannot manage owners' do
      let(:user) { maintainer }

      it 'returns Gitlab::Access.options' do
        expect(access_levels).to eq(Gitlab::Access.options)
      end
    end

    context 'when the user is a developer' do
      let(:user) { developer }

      it 'returns Gitlab::Access.options' do
        expect(access_levels).to eq({
          "Guest" => 10,
          "Planner" => 15,
          "Reporter" => 20,
          "Developer" => 30
        })
      end
    end
  end

  describe '#real_source_type' do
    subject { create(:project_member).real_source_type }

    it { is_expected.to eq 'Project' }
  end

  describe "#destroy" do
    let(:owner)   { create(:project_member, access_level: ProjectMember::MAINTAINER) }
    let(:project) { owner.project }
    let(:maintainer) { create(:project_member, project: project) }

    it "creates an expired event when left due to expiry" do
      expired = create(:project_member, project: project, expires_at: 1.day.from_now)
      travel_to(2.days.from_now) { expired.destroy! }

      expect(Event.recent.first).to be_expired_action
    end

    it "creates a left event when left due to leave" do
      maintainer.destroy!
      expect(Event.recent.first).to be_left_action
    end

    context 'for an orphaned member' do
      let!(:orphaned_project_member) do
        owner.tap { |member| member.update_column(:user_id, nil) }
      end

      it 'does not raise an error' do
        expect { orphaned_project_member.destroy! }.not_to raise_error
      end
    end
  end

  describe '#holder_of_the_personal_namespace?' do
    let_it_be(:project_member) { build(:project_member) }

    using RSpec::Parameterized::TableSyntax

    where(:personal_namespace_holder?, :expected) do
      false | false
      true  | true
    end

    with_them do
      it "returns expected" do
        allow(project_member.project).to receive(:personal_namespace_holder?)
          .with(project_member.user)
          .and_return(personal_namespace_holder?)

        expect(project_member.holder_of_the_personal_namespace?).to be(expected)
      end
    end
  end

  describe '.truncate_teams' do
    before do
      @project_1 = create(:project)
      @project_2 = create(:project)

      @user_1 = create :user
      @user_2 = create :user

      @project_1.add_developer(@user_1)
      @project_2.add_reporter(@user_2)

      described_class.truncate_teams([@project_1.id, @project_2.id])
    end

    it { expect(@project_1.users).to be_empty }
    it { expect(@project_2.users).to be_empty }
  end

  it_behaves_like 'members notifications', :project

  context 'access levels' do
    context 'with parent group' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:entity) { create(:project, group: parent_entity) }
      end
    end

    context 'with parent group and a subgroup' do
      it_behaves_like 'inherited access level as a member of entity' do
        let(:subgroup) { create(:group, parent: parent_entity) }
        let(:entity) { create(:project, group: subgroup) }
      end
    end
  end

  context 'refreshing project_authorizations' do
    let_it_be_with_refind(:project) { create(:project) }
    let_it_be_with_refind(:user) { create(:user) }
    let_it_be(:project_member) { create(:project_member, :guest, project: project, user: user) }

    context 'when the source project of the project member is destroyed' do
      it 'refreshes the authorization of user to the project in the group' do
        expect { project.destroy! }.to change { user.can?(:guest_access, project) }.from(true).to(false)
      end

      it 'refreshes the authorization without calling AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker' do
        # this is inline with the overridden behaviour in stubbed_member.rb
        expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).not_to receive(:new)

        project.destroy!
      end
    end

    context 'when the user of the project member is destroyed' do
      it 'refreshes the authorization of user to the project in the group' do
        expect(project.authorized_users).to include(user)

        user.destroy!

        expect(project.authorized_users).not_to include(user)
      end

      it 'refreshes the authorization without calling `AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker`' do
        # this is inline with the overridden behaviour in stubbed_member.rb
        expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).not_to receive(:new)

        user.destroy!
      end
    end

    context 'when importing' do
      it 'does not refresh' do
        # this is inline with the overridden behaviour in stubbed_member.rb
        expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).not_to receive(:new)

        member = build(:project_member, project: project)
        member.importing = true
        member.save!
      end
    end
  end

  context 'authorization refresh on addition/updation/deletion' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user) }

    shared_examples_for 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker inline to recalculate authorizations' do
      # this is inline with the overridden behaviour in stubbed_member.rb
      it 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker inline' do
        worker_instance = AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker.new
        expect(AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker).to receive(:new).and_return(worker_instance)
        expect(worker_instance).to receive(:perform).with(project.id, user.id)

        action
      end
    end

    shared_examples_for 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations' do
      it 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker' do
        stub_feature_flags(do_not_run_safety_net_auth_refresh_jobs: false)

        expect(AuthorizedProjectUpdate::UserRefreshFromReplicaWorker).to(
          receive(:bulk_perform_in).with(1.hour, [[user.id]], batch_delay: 30.seconds, batch_size: 100)
        )

        action
      end
    end

    context 'on create' do
      let(:action) { project.add_member(user, Gitlab::Access::GUEST) }

      it 'changes access level' do
        expect { action }.to change { user.can?(:guest_access, project) }.from(false).to(true)
      end

      it_behaves_like 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker inline to recalculate authorizations'
      it_behaves_like 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations'
    end

    context 'on update' do
      let(:action) { project.members.find_by(user: user).update!(access_level: Gitlab::Access::DEVELOPER) }

      before do
        project.add_member(user, Gitlab::Access::GUEST)
      end

      it 'changes access level' do
        expect { action }.to change { user.can?(:developer_access, project) }.from(false).to(true)
      end

      it_behaves_like 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker inline to recalculate authorizations'
      it_behaves_like 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations'
    end

    context 'on destroy' do
      let(:action) { project.members.find_by(user: user).destroy! }

      before do
        project.add_member(user, Gitlab::Access::GUEST)
      end

      it 'changes access level' do
        expect { action }.to change { user.can?(:guest_access, project) }.from(true).to(false)
      end

      it_behaves_like 'calls AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker inline to recalculate authorizations'
      it_behaves_like 'calls AuthorizedProjectUpdate::UserRefreshFromReplicaWorker with a delay to update project authorizations'
    end
  end

  describe '#set_member_namespace_id' do
    let(:project) { create(:project) }
    let(:member) { create(:project_member, project: project) }

    context 'on create' do
      it 'sets the member_namespace_id' do
        expect(member.member_namespace_id).to eq project.project_namespace_id
      end
    end
  end
end
