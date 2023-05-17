# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Group, feature_category: :subgroups do
  include ReloadHelpers
  include StubGitlabCalls

  let!(:group) { create(:group) }

  describe 'associations' do
    it { is_expected.to have_many :projects }
    it { is_expected.to have_many(:group_members).dependent(:destroy) }
    it { is_expected.to have_many(:namespace_members) }
    it { is_expected.to have_many(:users).through(:group_members) }
    it { is_expected.to have_many(:owners).through(:group_members) }
    it { is_expected.to have_many(:requesters).dependent(:destroy) }
    it { is_expected.to have_many(:namespace_requesters) }
    it { is_expected.to have_many(:members_and_requesters) }
    it { is_expected.to have_many(:namespace_members_and_requesters) }
    it { is_expected.to have_many(:project_group_links).dependent(:destroy) }
    it { is_expected.to have_many(:shared_projects).through(:project_group_links) }
    it { is_expected.to have_many(:notification_settings).dependent(:destroy) }
    it { is_expected.to have_many(:labels).class_name('GroupLabel') }
    it { is_expected.to have_many(:variables).class_name('Ci::GroupVariable') }
    it { is_expected.to have_many(:uploads) }
    it { is_expected.to have_one(:chat_team) }
    it { is_expected.to have_many(:custom_attributes).class_name('GroupCustomAttribute') }
    it { is_expected.to have_many(:badges).class_name('GroupBadge') }
    it { is_expected.to have_many(:cluster_groups).class_name('Clusters::Group') }
    it { is_expected.to have_many(:clusters).class_name('Clusters::Cluster') }
    it { is_expected.to have_many(:container_repositories) }
    it { is_expected.to have_many(:milestones) }
    it { is_expected.to have_many(:group_deploy_keys) }
    it { is_expected.to have_many(:integrations) }
    it { is_expected.to have_one(:dependency_proxy_setting) }
    it { is_expected.to have_one(:dependency_proxy_image_ttl_policy) }
    it { is_expected.to have_many(:dependency_proxy_blobs) }
    it { is_expected.to have_many(:dependency_proxy_manifests) }
    it { is_expected.to have_many(:debian_distributions).class_name('Packages::Debian::GroupDistribution').dependent(:destroy) }
    it { is_expected.to have_many(:daily_build_group_report_results).class_name('Ci::DailyBuildGroupReportResult') }
    it { is_expected.to have_many(:group_callouts).class_name('Users::GroupCallout').with_foreign_key(:group_id) }

    it { is_expected.to have_many(:bulk_import_exports).class_name('BulkImports::Export') }

    it do
      is_expected.to have_many(:bulk_import_entities).class_name('BulkImports::Entity')
        .with_foreign_key(:namespace_id).inverse_of(:group)
    end

    it { is_expected.to have_many(:contacts).class_name('CustomerRelations::Contact') }
    it { is_expected.to have_many(:organizations).class_name('CustomerRelations::Organization') }
    it { is_expected.to have_many(:protected_branches).inverse_of(:group).with_foreign_key(:namespace_id) }
    it { is_expected.to have_one(:crm_settings) }
    it { is_expected.to have_one(:group_feature) }
    it { is_expected.to have_one(:harbor_integration) }

    describe '#namespace_members' do
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }

      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(group.namespace_members).to include Member.find_by(user: developer)
        expect(group.namespace_members).not_to include Member.find_by(user: requester)
      end

      it 'is equivelent to #group_members' do
        expect(group.namespace_members).to eq group.group_members
      end

      it_behaves_like 'query without source filters' do
        subject { group.namespace_members }
      end
    end

    describe '#namespace_requesters' do
      let(:requester) { create(:user) }
      let(:developer) { create(:user) }

      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(group.namespace_requesters).to include Member.find_by(user: requester)
        expect(group.namespace_requesters).not_to include Member.find_by(user: developer)
      end

      it 'is equivalent to #requesters' do
        expect(group.namespace_requesters).to eq group.requesters
      end

      it_behaves_like 'query without source filters' do
        subject { group.namespace_requesters }
      end
    end

    describe '#namespace_members_and_requesters' do
      let_it_be(:group) { create(:group) }
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }
      let_it_be(:invited_member) { create(:group_member, :invited, :owner, group: group) }

      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      it 'includes the correct users' do
        expect(group.namespace_members_and_requesters).to include(
          Member.find_by(user: requester),
          Member.find_by(user: developer),
          Member.find(invited_member.id)
        )
      end

      it 'is equivalent to #members_and_requesters' do
        expect(group.namespace_members_and_requesters).to match_array group.members_and_requesters
      end

      it_behaves_like 'query without source filters' do
        subject { group.namespace_members_and_requesters }
      end
    end

    shared_examples 'polymorphic membership relationship' do
      it do
        expect(membership.attributes).to include(
          'source_type' => 'Namespace',
          'source_id' => group.id
        )
      end
    end

    shared_examples 'member_namespace membership relationship' do
      it do
        expect(membership.attributes).to include(
          'member_namespace_id' => group.id
        )
      end
    end

    describe '#namespace_members setters' do
      let(:user) { create(:user) }
      let(:membership) { group.namespace_members.create!(user: user, access_level: Gitlab::Access::DEVELOPER) }

      it { expect(membership).to be_instance_of(GroupMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.group).to eq group }
      it { expect(membership.requested_at).to be_nil }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    describe '#namespace_requesters setters' do
      let(:requested_at) { Time.current }
      let(:user) { create(:user) }
      let(:membership) do
        group.namespace_requesters.create!(user: user, requested_at: requested_at, access_level: Gitlab::Access::DEVELOPER)
      end

      it { expect(membership).to be_instance_of(GroupMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.group).to eq group }
      it { expect(membership.requested_at).to eq requested_at }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    describe '#namespace_members_and_requesters setters' do
      let(:requested_at) { Time.current }
      let(:user) { create(:user) }
      let(:membership) do
        group.namespace_members_and_requesters.create!(
          user: user, requested_at: requested_at, access_level: Gitlab::Access::DEVELOPER
        )
      end

      it { expect(membership).to be_instance_of(GroupMember) }
      it { expect(membership.user).to eq user }
      it { expect(membership.group).to eq group }
      it { expect(membership.requested_at).to eq requested_at }

      it_behaves_like 'polymorphic membership relationship'
      it_behaves_like 'member_namespace membership relationship'
    end

    describe '#members & #requesters' do
      let_it_be(:requester) { create(:user) }
      let_it_be(:developer) { create(:user) }

      before do
        group.request_access(requester)
        group.add_developer(developer)
      end

      it_behaves_like 'members and requesters associations' do
        let(:namespace) { group }
      end
    end
  end

  describe 'modules' do
    subject { described_class }

    it { is_expected.to include_module(Referable) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of :name }
    it { is_expected.not_to allow_value('colon:in:path').for(:path) } # This is to validate that a specially crafted name cannot bypass a pattern match. See !72555
    it { is_expected.to allow_value('group test_4').for(:name) }
    it { is_expected.not_to allow_value('test/../foo').for(:name) }
    it { is_expected.not_to allow_value('<script>alert("Attack!")</script>').for(:name) }
    it { is_expected.to validate_presence_of :path }
    it { is_expected.not_to validate_presence_of :owner }
    it { is_expected.to validate_presence_of :two_factor_grace_period }
    it { is_expected.to validate_numericality_of(:two_factor_grace_period).is_greater_than_or_equal_to(0) }

    context 'validating the parent of a group' do
      context 'when the group has no parent' do
        it 'allows a group to have no parent associated with it' do
          group = build(:group)

          expect(group).to be_valid
        end
      end

      context 'when the group has a parent' do
        it 'does not allow a group to have a namespace as its parent' do
          group = build(:group, parent: build(:namespace))

          expect(group).not_to be_valid
          expect(group.errors[:parent_id].first).to eq('user namespace cannot be the parent of another namespace')
        end

        it 'allows a group to have another group as its parent' do
          group = build(:group, parent: build(:group))

          expect(group).to be_valid
        end

        it 'does not allow a subgroup to have the same name as an existing subgroup' do
          sub_group1 = create(:group, parent: group, name: "SG", path: 'api')
          sub_group2 = described_class.new(parent: group, name: "SG", path: 'api2')

          expect(sub_group1).to be_valid
          expect(sub_group2).not_to be_valid
          expect(sub_group2.errors.full_messages.to_sentence).to eq('Name has already been taken')
        end
      end
    end

    describe 'path validation' do
      it 'rejects paths reserved on the root namespace when the group has no parent' do
        group = build(:group, path: 'api')

        expect(group).not_to be_valid
      end

      it 'allows root paths when the group has a parent' do
        group = build(:group, path: 'api', parent: create(:group))

        expect(group).to be_valid
      end

      it 'rejects any wildcard paths when not a top level group' do
        group = build(:group, path: 'tree', parent: create(:group))

        expect(group).not_to be_valid
      end
    end

    describe '#notification_settings' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:sub_group) { create(:group, parent_id: group.id) }

      before do
        group.add_developer(user)
        sub_group.add_maintainer(user)
      end

      it 'also gets notification settings from parent groups' do
        expect(sub_group.notification_settings.size).to eq(2)
        expect(sub_group.notification_settings).to include(group.notification_settings.first)
      end

      context 'when sub group is deleted' do
        it 'does not delete parent notification settings' do
          expect do
            sub_group.destroy!
          end.to change { NotificationSetting.count }.by(-1)
        end
      end
    end

    describe '#notification_email_for' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:subgroup) { create(:group, parent: group) }

      let(:group_notification_email) { 'user+group@example.com' }
      let(:subgroup_notification_email) { 'user+subgroup@example.com' }

      before do
        create(:email, :confirmed, user: user, email: group_notification_email)
        create(:email, :confirmed, user: user, email: subgroup_notification_email)
      end

      subject { subgroup.notification_email_for(user) }

      context 'when both group notification emails are set' do
        it 'returns subgroup notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)
          create(:notification_setting, user: user, source: subgroup, notification_email: subgroup_notification_email)

          is_expected.to eq(subgroup_notification_email)
        end
      end

      context 'when subgroup notification email is blank' do
        it 'returns parent group notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)
          create(:notification_setting, user: user, source: subgroup, notification_email: '')

          is_expected.to eq(group_notification_email)
        end
      end

      context 'when only the parent group notification email is set' do
        it 'returns parent group notification email' do
          create(:notification_setting, user: user, source: group, notification_email: group_notification_email)

          is_expected.to eq(group_notification_email)
        end
      end
    end

    describe '#visibility_level_allowed_by_parent' do
      let(:parent) { create(:group, :internal) }
      let(:sub_group) { build(:group, parent_id: parent.id) }

      context 'without a parent' do
        it 'is valid' do
          sub_group.parent_id = nil

          expect(sub_group).to be_valid
        end
      end

      context 'with a parent' do
        context 'when visibility of sub group is greater than the parent' do
          it 'is invalid' do
            sub_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

            expect(sub_group).to be_invalid
          end
        end

        context 'when visibility of sub group is lower or equal to the parent' do
          [Gitlab::VisibilityLevel::INTERNAL, Gitlab::VisibilityLevel::PRIVATE].each do |level|
            it 'is valid' do
              sub_group.visibility_level = level

              expect(sub_group).to be_valid
            end
          end
        end
      end
    end

    describe '#visibility_level_allowed_by_projects' do
      let!(:internal_group) { create(:group, :internal) }
      let!(:internal_project) { create(:project, :internal, group: internal_group) }

      context 'when group has a lower visibility' do
        it 'is invalid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PRIVATE

          expect(internal_group).to be_invalid
          expect(internal_group.errors[:visibility_level]).to include('private is not allowed since this group contains projects with higher visibility.')
        end
      end

      context 'when group has a higher visibility' do
        it 'is valid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

          expect(internal_group).to be_valid
        end
      end
    end

    describe '#visibility_level_allowed_by_sub_groups' do
      let!(:internal_group) { create(:group, :internal) }
      let!(:internal_sub_group) { create(:group, :internal, parent: internal_group) }

      context 'when parent group has a lower visibility' do
        it 'is invalid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PRIVATE

          expect(internal_group).to be_invalid
          expect(internal_group.errors[:visibility_level]).to include('private is not allowed since there are sub-groups with higher visibility.')
        end
      end

      context 'when parent group has a higher visibility' do
        it 'is valid' do
          internal_group.visibility_level = Gitlab::VisibilityLevel::PUBLIC

          expect(internal_group).to be_valid
        end
      end
    end

    describe '#two_factor_authentication_allowed' do
      let_it_be_with_reload(:group) { create(:group) }

      context 'for a parent group' do
        it 'is valid' do
          group.require_two_factor_authentication = true

          expect(group).to be_valid
        end
      end

      context 'for a child group' do
        let(:sub_group) { create(:group, parent: group) }

        it 'is valid when parent group allows' do
          sub_group.require_two_factor_authentication = true

          expect(sub_group).to be_valid
        end

        it 'is invalid when parent group blocks' do
          group.namespace_settings.update!(allow_mfa_for_subgroups: false)
          sub_group.require_two_factor_authentication = true

          expect(sub_group).to be_invalid
          expect(sub_group.errors[:require_two_factor_authentication]).to include('is forbidden by a top-level group')
        end
      end
    end
  end

  it_behaves_like 'a BulkUsersByEmailLoad model'

  it_behaves_like 'ensures runners_token is prefixed', :group

  context 'after initialized' do
    it 'has a group_feature' do
      expect(described_class.new.group_feature).to be_present
    end
  end

  context 'when creating a new project' do
    let_it_be(:group) { create(:group) }

    it 'automatically creates the groups feature for the group' do
      expect(group.group_feature).to be_an_instance_of(Groups::FeatureSetting)
      expect(group.group_feature).to be_persisted
    end
  end

  context 'traversal_ids on create' do
    context 'default traversal_ids' do
      let(:group) { build(:group) }

      before do
        group.save!
      end

      it { expect(group.traversal_ids).to eq [group.id] }
    end

    context 'has a parent' do
      let(:parent) { create(:group) }
      let(:group) { build(:group, parent: parent) }

      before do
        group.save!
      end

      it { expect(parent.traversal_ids).to eq [parent.id] }
      it { expect(group.traversal_ids).to eq [parent.id, group.id] }
    end

    context 'has a parent update before save' do
      let(:parent) { create(:group) }
      let(:group) { build(:group, parent: parent) }
      let!(:new_grandparent) { create(:group) }

      before do
        parent.update!(parent: new_grandparent)
        group.save!
      end

      it 'avoid traversal_ids race condition' do
        expect(parent.traversal_ids).to eq [new_grandparent.id, parent.id]
        expect(group.traversal_ids).to eq [new_grandparent.id, parent.id, group.id]
      end
    end
  end

  context 'traversal_ids on update' do
    context 'parent is updated' do
      let(:new_parent) { create(:group) }

      subject { group.update!(parent: new_parent, name: 'new name') }

      it_behaves_like 'update on column', :traversal_ids
    end

    context 'parent is not updated' do
      subject { group.update!(name: 'new name') }

      it_behaves_like 'no update on column', :traversal_ids
    end
  end

  context 'traversal_ids on ancestral update' do
    context 'update multiple ancestors before save' do
      let(:parent) { create(:group) }
      let(:group) { create(:group, parent: parent) }
      let!(:new_grandparent) { create(:group) }
      let!(:new_parent) { create(:group) }

      before do
        group.parent = new_parent
        new_parent.update!(parent: new_grandparent)

        group.save!
      end

      it 'avoids traversal_ids race condition' do
        expect(parent.traversal_ids).to eq [parent.id]
        expect(group.traversal_ids).to eq [new_grandparent.id, new_parent.id, group.id]
        expect(new_grandparent.traversal_ids).to eq [new_grandparent.id]
        expect(new_parent.traversal_ids).to eq [new_grandparent.id, new_parent.id]
      end
    end

    context 'assign a new parent' do
      let!(:group) { create(:group, parent: old_parent) }
      let(:recorded_queries) { ActiveRecord::QueryRecorder.new }

      subject do
        recorded_queries.record do
          group.update!(parent: new_parent)
        end
      end

      context 'within the same hierarchy' do
        let!(:root) { create(:group) }
        let!(:old_parent) { create(:group, parent: root) }
        let!(:new_parent) { create(:group, parent: root) }

        context 'with FOR NO KEY UPDATE lock' do
          before do
            subject
          end

          it 'updates traversal_ids' do
            expect(group.traversal_ids).to eq [root.id, new_parent.id, group.id]
          end

          it_behaves_like 'hierarchy with traversal_ids'
          it_behaves_like 'locked row' do
            let(:row) { root }
          end
        end
      end

      context 'to another hierarchy' do
        let!(:old_parent) { create(:group) }
        let!(:new_parent) { create(:group) }
        let!(:group) { create(:group, parent: old_parent) }

        before do
          subject
        end

        it 'updates traversal_ids' do
          expect(group.traversal_ids).to eq [new_parent.id, group.id]
        end

        it_behaves_like 'locked rows' do
          let(:rows) { [old_parent, new_parent] }
        end

        context 'old hierarchy' do
          let(:root) { old_parent.root_ancestor }

          it_behaves_like 'hierarchy with traversal_ids'
        end

        context 'new hierarchy' do
          let(:root) { new_parent.root_ancestor }

          it_behaves_like 'hierarchy with traversal_ids'
        end
      end

      context 'from being a root ancestor' do
        let!(:old_parent) { nil }
        let!(:new_parent) { create(:group) }

        before do
          subject
        end

        it 'updates traversal_ids' do
          expect(group.traversal_ids).to eq [new_parent.id, group.id]
        end

        it_behaves_like 'locked rows' do
          let(:rows) { [group, new_parent] }
        end

        it_behaves_like 'hierarchy with traversal_ids' do
          let(:root) { new_parent }
        end
      end

      context 'to being a root ancestor' do
        let!(:old_parent) { create(:group) }
        let!(:new_parent) { nil }

        before do
          subject
        end

        it 'updates traversal_ids' do
          expect(group.traversal_ids).to eq [group.id]
        end

        it_behaves_like 'locked rows' do
          let(:rows) { [old_parent, group] }
        end

        it_behaves_like 'hierarchy with traversal_ids' do
          let(:root) { group }
        end
      end
    end

    context 'assigning a new grandparent' do
      let!(:old_grandparent) { create(:group) }
      let!(:new_grandparent) { create(:group) }
      let!(:parent_group) { create(:group, parent: old_grandparent) }
      let!(:group) { create(:group, parent: parent_group) }

      before do
        parent_group.update!(parent: new_grandparent)
        reload_models(parent_group, group)
      end

      it 'updates traversal_ids for all descendants' do
        expect(parent_group.traversal_ids).to eq [new_grandparent.id, parent_group.id]
        expect(group.traversal_ids).to eq [new_grandparent.id, parent_group.id, group.id]
      end
    end
  end

  context 'traversal queries' do
    let_it_be(:group, reload: true) { create(:group, :nested) }

    context 'recursive' do
      before do
        stub_feature_flags(use_traversal_ids: false)
      end

      it_behaves_like 'namespace traversal'

      describe '#self_and_descendants' do
        it { expect(group.self_and_descendants.to_sql).not_to include 'traversal_ids @>' }
      end

      describe '#self_and_descendant_ids' do
        it { expect(group.self_and_descendant_ids.to_sql).not_to include 'traversal_ids @>' }
      end

      describe '#descendants' do
        it { expect(group.descendants.to_sql).not_to include 'traversal_ids @>' }
      end

      describe '#self_and_hierarchy' do
        it { expect(group.self_and_hierarchy.to_sql).not_to include 'traversal_ids @>' }
      end

      describe '#ancestors' do
        it { expect(group.ancestors.to_sql).not_to include 'traversal_ids <@' }
      end

      describe '#ancestors_upto' do
        it { expect(group.ancestors_upto.to_sql).not_to include "WITH ORDINALITY" }
      end

      describe '.shortest_traversal_ids_prefixes' do
        it { expect { described_class.shortest_traversal_ids_prefixes }.to raise_error /Feature not supported since the `:use_traversal_ids` is disabled/ }
      end
    end

    context 'linear' do
      it_behaves_like 'namespace traversal'

      describe '#self_and_descendants' do
        it { expect(group.self_and_descendants.to_sql).to include 'traversal_ids @>' }
      end

      describe '#self_and_descendant_ids' do
        it { expect(group.self_and_descendant_ids.to_sql).to include 'traversal_ids @>' }
      end

      describe '#descendants' do
        it { expect(group.descendants.to_sql).to include 'traversal_ids @>' }
      end

      describe '#self_and_hierarchy' do
        it { expect(group.self_and_hierarchy.to_sql).to include 'traversal_ids @>' }
      end

      describe '#ancestors' do
        it { expect(group.ancestors.to_sql).to include "\"namespaces\".\"id\" = #{group.parent_id}" }

        it 'hierarchy order' do
          expect(group.ancestors(hierarchy_order: :asc).to_sql).to include 'ORDER BY "depth" ASC'
        end

        context 'ancestor linear queries feature flag disabled' do
          before do
            stub_feature_flags(use_traversal_ids_for_ancestors: false)
          end

          it { expect(group.ancestors.to_sql).not_to include 'traversal_ids <@' }
        end
      end

      describe '#ancestors_upto' do
        it { expect(group.ancestors_upto.to_sql).to include "WITH ORDINALITY" }
      end

      describe '.shortest_traversal_ids_prefixes' do
        subject { filter.shortest_traversal_ids_prefixes }

        context 'for many top-level namespaces' do
          let!(:top_level_groups) { create_list(:group, 4) }

          context 'when querying all groups' do
            let(:filter) { described_class.id_in(top_level_groups) }

            it "returns all traversal_ids" do
              is_expected.to contain_exactly(
                *top_level_groups.map { |group| [group.id] }
              )
            end
          end

          context 'when querying selected groups' do
            let(:filter) { described_class.id_in(top_level_groups.first) }

            it "returns only a selected traversal_ids" do
              is_expected.to contain_exactly([top_level_groups.first.id])
            end
          end
        end

        context 'for namespace hierarchy' do
          let!(:group_a) { create(:group) }
          let!(:group_a_sub_1) { create(:group, parent: group_a) }
          let!(:group_a_sub_2) { create(:group, parent: group_a) }
          let!(:group_b) { create(:group) }
          let!(:group_b_sub_1) { create(:group, parent: group_b) }
          let!(:group_c) { create(:group) }

          context 'when querying all groups' do
            let(:filter) { described_class.id_in([group_a, group_a_sub_1, group_a_sub_2, group_b, group_b_sub_1, group_c]) }

            it 'returns only shortest prefixes of top-level groups' do
              is_expected.to contain_exactly(
                [group_a.id],
                [group_b.id],
                [group_c.id]
              )
            end
          end

          context 'when sub-group is reparented' do
            let(:filter) { described_class.id_in([group_b_sub_1, group_c]) }

            before do
              group_b_sub_1.update!(parent: group_c)
            end

            it 'returns a proper shortest prefix of a new group' do
              is_expected.to contain_exactly(
                [group_c.id]
              )
            end
          end

          context 'when querying sub-groups' do
            let(:filter) { described_class.id_in([group_a_sub_1, group_b_sub_1, group_c]) }

            it 'returns sub-groups as they are shortest prefixes' do
              is_expected.to contain_exactly(
                [group_a.id, group_a_sub_1.id],
                [group_b.id, group_b_sub_1.id],
                [group_c.id]
              )
            end
          end

          context 'when querying group and sub-group of this group' do
            let(:filter) { described_class.id_in([group_a, group_a_sub_1, group_c]) }

            it 'returns parent groups as this contains all sub-groups' do
              is_expected.to contain_exactly(
                [group_a.id],
                [group_c.id]
              )
            end
          end
        end
      end

      context 'when project namespace exists in the group' do
        let!(:project) { create(:project, group: group) }
        let!(:project_namespace) { project.project_namespace }

        it 'filters out project namespace' do
          expect(group.descendants.find_by_id(project_namespace.id)).to be_nil
        end
      end
    end
  end

  describe '.without_integration' do
    let(:another_group) { create(:group) }
    let(:instance_integration) { build(:jira_integration, :instance) }

    before do
      create(:jira_integration, :group, group: group)
      create(:integrations_slack, :group, group: another_group)
    end

    it 'returns groups without integration' do
      expect(Group.without_integration(instance_integration)).to contain_exactly(another_group)
    end
  end

  describe '.public_or_visible_to_user' do
    let!(:private_group) { create(:group, :private) }
    let!(:private_subgroup) { create(:group, :private, parent: private_group) }
    let!(:internal_group) { create(:group, :internal) }

    subject { described_class.public_or_visible_to_user(user) }

    context 'when user is nil' do
      let!(:user) { nil }

      it { is_expected.to match_array([group]) }
    end

    context 'when user' do
      let!(:user) { create(:user) }

      context 'when user does not have access to any private group' do
        it { is_expected.to match_array([internal_group, group]) }
      end

      context 'when user is a member of private group' do
        before do
          private_group.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to match_array([private_group, internal_group, group]) }

        it 'does not have access to subgroups (see accessible_to_user scope)' do
          is_expected.not_to include(private_subgroup)
        end
      end

      context 'when user is a member of private subgroup' do
        let!(:private_subgroup) { create(:group, :private, parent: private_group) }

        before do
          private_subgroup.add_member(user, Gitlab::Access::DEVELOPER)
        end

        it { is_expected.to match_array([private_subgroup, internal_group, group]) }
      end
    end
  end

  describe 'scopes' do
    let_it_be(:private_group)  { create(:group, :private)  }
    let_it_be(:internal_group) { create(:group, :internal) }
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }

    describe 'public_only' do
      subject { described_class.public_only.to_a }

      it { is_expected.to eq([group]) }
    end

    describe 'public_and_internal_only' do
      subject { described_class.public_and_internal_only.to_a }

      it { is_expected.to match_array([group, internal_group]) }
    end

    describe 'non_public_only' do
      subject { described_class.non_public_only.to_a }

      it { is_expected.to match_array([private_group, internal_group]) }
    end

    describe 'private_only' do
      subject { described_class.private_only.to_a }

      it { is_expected.to match_array([private_group]) }
    end

    describe 'with_onboarding_progress' do
      subject { described_class.with_onboarding_progress }

      it 'joins onboarding_progress' do
        create(:onboarding_progress, namespace: group)

        expect(subject).to eq([group])
      end
    end

    describe 'for_authorized_group_members' do
      let_it_be(:group_member1) { create(:group_member, source: private_group, user_id: user1.id, access_level: Gitlab::Access::OWNER) }

      it do
        result = described_class.for_authorized_group_members([user1.id, user2.id])

        expect(result).to match_array([private_group])
      end
    end

    describe 'for_authorized_project_members' do
      let_it_be(:project) { create(:project, group: internal_group) }
      let_it_be(:project_member1) { create(:project_member, source: project, user_id: user1.id, access_level: Gitlab::Access::DEVELOPER) }

      it do
        result = described_class.for_authorized_project_members([user1.id, user2.id])

        expect(result).to match_array([internal_group])
      end
    end

    describe '.with_project_creation_levels' do
      let_it_be(:group_1) { create(:group, project_creation_level: Gitlab::Access::NO_ONE_PROJECT_ACCESS) }
      let_it_be(:group_2) { create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }
      let_it_be(:group_3) { create(:group, project_creation_level: Gitlab::Access::MAINTAINER_PROJECT_ACCESS) }
      let_it_be(:group_4) { create(:group, project_creation_level: nil) }

      it 'returns groups with the specified project creation levels' do
        result = described_class.with_project_creation_levels([
          Gitlab::Access::NO_ONE_PROJECT_ACCESS,
          Gitlab::Access::MAINTAINER_PROJECT_ACCESS
        ])

        expect(result).to include(group_1, group_3)
        expect(result).not_to include(group_2, group_4)
      end
    end

    describe '.project_creation_allowed' do
      let_it_be(:group_1) { create(:group, project_creation_level: Gitlab::Access::NO_ONE_PROJECT_ACCESS) }
      let_it_be(:group_2) { create(:group, project_creation_level: Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS) }
      let_it_be(:group_3) { create(:group, project_creation_level: Gitlab::Access::MAINTAINER_PROJECT_ACCESS) }
      let_it_be(:group_4) { create(:group, project_creation_level: nil) }

      it 'only includes groups where project creation is allowed' do
        result = described_class.project_creation_allowed

        expect(result).to include(group_2, group_3, group_4)
        expect(result).not_to include(group_1)
      end

      context 'when the application_setting is set to `NO_ONE_PROJECT_ACCESS`' do
        before do
          stub_application_setting(default_project_creation: Gitlab::Access::NO_ONE_PROJECT_ACCESS)
        end

        it 'only includes groups where project creation is allowed' do
          result = described_class.project_creation_allowed

          expect(result).to include(group_2, group_3)

          # group_4 won't be included because it has `project_creation_level: nil`,
          # and that means it behaves like the value of the application_setting will inherited.
          expect(result).not_to include(group_1, group_4)
        end
      end
    end

    describe 'by_ids_or_paths' do
      let(:group_path) { 'group_path' }
      let!(:group) { create(:group, path: group_path) }
      let(:group_id) { group.id }

      it 'returns matching records based on paths' do
        expect(described_class.by_ids_or_paths(nil, [group_path])).to match_array([group])
        expect(described_class.by_ids_or_paths(nil, [group_path.upcase])).to match_array([group])
      end

      it 'returns matching records based on ids' do
        expect(described_class.by_ids_or_paths([group_id], nil)).to match_array([group])
        expect(described_class.by_ids_or_paths([group_id], [])).to match_array([group])
      end

      it 'returns matching records based on both paths and ids' do
        new_group = create(:group)

        expect(described_class.by_ids_or_paths([new_group.id], [group_path])).to match_array([group, new_group])
      end

      it 'returns matching records based on full_paths' do
        new_group = create(:group, parent: group)

        expect(described_class.by_ids_or_paths(nil, [new_group.full_path])).to match_array([new_group])
        expect(described_class.by_ids_or_paths(nil, [new_group.full_path.upcase])).to match_array([new_group])
      end
    end

    describe 'accessible_to_user' do
      subject { described_class.accessible_to_user(user) }

      let_it_be(:public_group) { create(:group, :public) }
      let_it_be(:unaccessible_group) { create(:group, :private) }
      let_it_be(:unaccessible_subgroup) { create(:group, :private, parent: unaccessible_group) }
      let_it_be(:accessible_group) { create(:group, :private) }
      let_it_be(:accessible_subgroup) { create(:group, :private, parent: accessible_group) }

      context 'when user is nil' do
        let(:user) { nil }

        it { is_expected.to match_array([group, public_group]) }
      end

      context 'when user is present' do
        let(:user) { create(:user) }

        it { is_expected.to match_array([group, internal_group, public_group]) }

        context 'when user has access to accessible group' do
          before do
            accessible_group.add_developer(user)
          end

          it { is_expected.to match_array([group, internal_group, public_group, accessible_group, accessible_subgroup]) }
        end
      end
    end
  end

  describe '#to_reference' do
    it 'returns a String reference to the object' do
      expect(group.to_reference).to eq "@#{group.name}"
    end
  end

  describe '#users' do
    it { expect(group.users).to eq(group.owners) }
  end

  describe '#human_name' do
    it { expect(group.human_name).to eq(group.name) }
  end

  describe '#add_user' do
    let(:user) { create(:user) }

    it 'adds the user' do
      expect_next_instance_of(GroupMember) do |member|
        expect(member).to receive(:refresh_member_authorized_projects).and_call_original
      end

      group.add_member(user, GroupMember::MAINTAINER)

      expect(group.group_members.maintainers.map(&:user)).to include(user)
    end
  end

  describe '#add_users' do
    let(:user) { create(:user) }

    before do
      group.add_members([user.id], GroupMember::GUEST)
    end

    it "updates the group permission" do
      expect(group.group_members.guests.map(&:user)).to include(user)
      group.add_members([user.id], GroupMember::DEVELOPER)
      expect(group.group_members.developers.map(&:user)).to include(user)
      expect(group.group_members.guests.map(&:user)).not_to include(user)
    end

    context 'when `tasks_to_be_done` and `tasks_project_id` are passed' do
      let!(:project) { create(:project, group: group) }

      before do
        group.add_members([create(:user)], :developer, tasks_to_be_done: %w(ci code), tasks_project_id: project.id)
      end

      it 'creates a member_task with the correct attributes', :aggregate_failures do
        member = group.group_members.last

        expect(member.tasks_to_be_done).to match_array([:ci, :code])
        expect(member.member_task.project).to eq(project)
      end
    end
  end

  describe '#avatar_type' do
    let(:user) { create(:user) }

    before do
      group.add_member(user, GroupMember::MAINTAINER)
    end

    it "is true if avatar is image" do
      group.update_attribute(:avatar, 'uploads/avatar.png')
      expect(group.avatar_type).to be_truthy
    end

    it "is false if avatar is html page" do
      group.update_attribute(:avatar, 'uploads/avatar.html')
      group.avatar_type

      expect(group.errors.added?(:avatar, "file format is not supported. Please try one of the following supported formats: png, jpg, jpeg, gif, bmp, tiff, ico, webp")).to be true
    end
  end

  describe '#avatar_url' do
    let!(:group) { create(:group, :with_avatar) }
    let(:user) { create(:user) }

    context 'when avatar file is uploaded' do
      before do
        group.add_maintainer(user)
      end

      it 'shows correct avatar url' do
        expect(group.avatar_url).to eq(group.avatar.url)
        expect(group.avatar_url(only_path: false)).to eq([Gitlab.config.gitlab.url, group.avatar.url].join)
      end
    end
  end

  describe '.search' do
    it 'returns groups with a matching name' do
      expect(described_class.search(group.name)).to eq([group])
    end

    it 'returns groups with a partially matching name' do
      expect(described_class.search(group.name[0..2])).to eq([group])
    end

    it 'returns groups with a matching name regardless of the casing' do
      expect(described_class.search(group.name.upcase)).to eq([group])
    end

    it 'returns groups with a matching path' do
      expect(described_class.search(group.path)).to eq([group])
    end

    it 'returns groups with a partially matching path' do
      expect(described_class.search(group.path[0..2])).to eq([group])
    end

    it 'returns groups with a matching path regardless of the casing' do
      expect(described_class.search(group.path.upcase)).to eq([group])
    end
  end

  describe '#has_owner?' do
    before do
      @members = setup_group_members(group)
      create(:group_member, :invited, :owner, group: group)
    end

    it { expect(group.has_owner?(@members[:owner])).to be_truthy }
    it { expect(group.has_owner?(@members[:maintainer])).to be_falsey }
    it { expect(group.has_owner?(@members[:developer])).to be_falsey }
    it { expect(group.has_owner?(@members[:reporter])).to be_falsey }
    it { expect(group.has_owner?(@members[:guest])).to be_falsey }
    it { expect(group.has_owner?(@members[:requester])).to be_falsey }
    it { expect(group.has_owner?(nil)).to be_falsey }
  end

  describe '#has_maintainer?' do
    before do
      @members = setup_group_members(group)
      create(:group_member, :invited, :maintainer, group: group)
    end

    it { expect(group.has_maintainer?(@members[:owner])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:maintainer])).to be_truthy }
    it { expect(group.has_maintainer?(@members[:developer])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:reporter])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:guest])).to be_falsey }
    it { expect(group.has_maintainer?(@members[:requester])).to be_falsey }
    it { expect(group.has_maintainer?(nil)).to be_falsey }
  end

  describe '#last_owner?' do
    before do
      @members = setup_group_members(group)
    end

    it { expect(group.last_owner?(@members[:owner])).to be_truthy }

    context 'there is also a project_bot owner' do
      before do
        group.add_member(create(:user, :project_bot), GroupMember::OWNER)
      end

      it { expect(group.last_owner?(@members[:owner])).to be_truthy }
    end

    context 'with two owners' do
      before do
        create(:group_member, :owner, group: group)
      end

      it { expect(group.last_owner?(@members[:owner])).to be_falsy }
    end

    context 'with owners from a parent' do
      context 'when top-level group' do
        it { expect(group.last_owner?(@members[:owner])).to be_truthy }

        context 'with group sharing' do
          let!(:subgroup) { create(:group, parent: group) }

          before do
            create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
            create(:group_member, :owner, group: subgroup)
          end

          it { expect(group.last_owner?(@members[:owner])).to be_truthy }
        end
      end

      context 'when subgroup' do
        let!(:subgroup) { create(:group, parent: group) }

        it { expect(subgroup.last_owner?(@members[:owner])).to be_truthy }

        context 'with two owners' do
          before do
            create(:group_member, :owner, group: group)
          end

          it { expect(subgroup.last_owner?(@members[:owner])).to be_falsey }
        end
      end
    end
  end

  describe '#member_last_blocked_owner?' do
    let!(:blocked_user) { create(:user, :blocked) }

    let!(:member) { group.add_member(blocked_user, GroupMember::OWNER) }

    context 'when last_blocked_owner is set' do
      before do
        expect(group).not_to receive(:member_owners_excluding_project_bots)
      end

      it 'returns true' do
        member.last_blocked_owner = true

        expect(group.member_last_blocked_owner?(member)).to be(true)
      end

      it 'returns false' do
        member.last_blocked_owner = false

        expect(group.member_last_blocked_owner?(member)).to be(false)
      end
    end

    context 'when last_blocked_owner is not set' do
      it { expect(group.member_last_blocked_owner?(member)).to be(true) }

      context 'with another active owner' do
        before do
          group.add_member(create(:user), GroupMember::OWNER)
        end

        it { expect(group.member_last_blocked_owner?(member)).to be(false) }
      end

      context 'with another active project_bot owner' do
        before do
          group.add_member(create(:user, :project_bot), GroupMember::OWNER)
        end

        it { expect(group.member_last_blocked_owner?(member)).to be(true) }
      end

      context 'with 2 blocked owners' do
        before do
          group.add_member(create(:user, :blocked), GroupMember::OWNER)
        end

        it { expect(group.member_last_blocked_owner?(member)).to be(false) }
      end

      context 'with owners from a parent' do
        context 'when top-level group' do
          it { expect(group.member_last_blocked_owner?(member)).to be(true) }

          context 'with group sharing' do
            let!(:subgroup) { create(:group, parent: group) }

            before do
              create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
              create(:group_member, :owner, group: subgroup)
            end

            it { expect(group.member_last_blocked_owner?(member)).to be(true) }
          end
        end

        context 'when subgroup' do
          let!(:subgroup) { create(:group, :nested) }

          let!(:member) { subgroup.add_member(blocked_user, GroupMember::OWNER) }

          it { expect(subgroup.member_last_blocked_owner?(member)).to be(true) }

          context 'with two owners' do
            before do
              create(:group_member, :owner, group: subgroup.parent)
            end

            it { expect(subgroup.member_last_blocked_owner?(member)).to be(false) }
          end
        end
      end
    end
  end

  context 'when analyzing blocked owners' do
    let_it_be(:blocked_user) { create(:user, :blocked) }

    describe '#single_blocked_owner?' do
      context 'when there is only one blocked owner' do
        before do
          group.add_member(blocked_user, GroupMember::OWNER)
        end

        it 'returns true' do
          expect(group.single_blocked_owner?).to eq(true)
        end
      end

      context 'when there are multiple blocked owners' do
        let_it_be(:blocked_user_2) { create(:user, :blocked) }

        before do
          group.add_member(blocked_user, GroupMember::OWNER)
          group.add_member(blocked_user_2, GroupMember::OWNER)
        end

        it 'returns true' do
          expect(group.single_blocked_owner?).to eq(false)
        end
      end

      context 'when there are no blocked owners' do
        it 'returns false' do
          expect(group.single_blocked_owner?).to eq(false)
        end
      end
    end

    describe '#blocked_owners' do
      let_it_be(:user) { create(:user) }

      before do
        group.add_member(blocked_user, GroupMember::OWNER)
        group.add_member(user, GroupMember::OWNER)
      end

      it 'has only blocked owners' do
        expect(group.blocked_owners.map(&:user)).to match([blocked_user])
      end
    end
  end

  describe '#member_owners_excluding_project_bots' do
    let_it_be(:user) { create(:user) }

    let!(:member_owner) do
      group.add_member(user, GroupMember::OWNER)
    end

    it 'returns the member-owners' do
      expect(group.member_owners_excluding_project_bots).to contain_exactly(member_owner)
    end

    context 'there is also a project_bot owner' do
      before do
        group.add_member(create(:user, :project_bot), GroupMember::OWNER)
      end

      it 'returns only the human member-owners' do
        expect(group.member_owners_excluding_project_bots).to contain_exactly(member_owner)
      end
    end

    context 'with owners from a parent' do
      context 'when top-level group' do
        context 'with group sharing' do
          let!(:subgroup) { create(:group, parent: group) }

          before do
            create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
            subgroup.add_member(user, GroupMember::OWNER)
          end

          it 'returns only direct member-owners' do
            expect(group.member_owners_excluding_project_bots).to contain_exactly(member_owner)
          end
        end
      end

      context 'when subgroup' do
        let!(:subgroup) { create(:group, parent: group) }

        let_it_be(:user_2) { create(:user) }

        let!(:member_owner_2) do
          subgroup.add_member(user_2, GroupMember::OWNER)
        end

        it 'returns member-owners including parents' do
          expect(subgroup.member_owners_excluding_project_bots).to contain_exactly(member_owner, member_owner_2)
        end
      end
    end

    context 'when there are no owners' do
      let_it_be(:empty_group) { create(:group) }

      it 'returns an empty result' do
        expect(empty_group.member_owners_excluding_project_bots).to be_empty
      end
    end
  end

  describe '#member_last_owner?' do
    let_it_be(:user) { create(:user) }

    let(:member) { group.members.last }

    before do
      group.add_member(user, GroupMember::OWNER)
    end

    context 'when last_owner is set' do
      before do
        expect(group).not_to receive(:last_owner?)
      end

      it 'returns true' do
        member.last_owner = true

        expect(group.member_last_owner?(member)).to be(true)
      end

      it 'returns false' do
        member.last_owner = false

        expect(group.member_last_owner?(member)).to be(false)
      end
    end

    context 'when last_owner is not set' do
      it 'returns true' do
        expect(group).to receive(:last_owner?).and_call_original

        expect(group.member_last_owner?(member)).to be(true)
      end
    end
  end

  describe '#lfs_enabled?' do
    context 'LFS enabled globally' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(true)
      end

      it 'returns true when nothing is set' do
        expect(group.lfs_enabled?).to be_truthy
      end

      it 'returns false when set to false' do
        group.update_attribute(:lfs_enabled, false)

        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns true when set to true' do
        group.update_attribute(:lfs_enabled, true)

        expect(group.lfs_enabled?).to be_truthy
      end
    end

    context 'LFS disabled globally' do
      before do
        allow(Gitlab.config.lfs).to receive(:enabled).and_return(false)
      end

      it 'returns false when nothing is set' do
        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns false when set to false' do
        group.update_attribute(:lfs_enabled, false)

        expect(group.lfs_enabled?).to be_falsey
      end

      it 'returns false when set to true' do
        group.update_attribute(:lfs_enabled, true)

        expect(group.lfs_enabled?).to be_falsey
      end
    end
  end

  describe '#owners' do
    let(:owner) { create(:user) }
    let(:developer) { create(:user) }

    it 'returns the owners of a Group' do
      group.add_owner(owner)
      group.add_developer(developer)

      expect(group.owners).to eq([owner])
    end
  end

  def setup_group_members(group)
    members = {
      owner: create(:user),
      maintainer: create(:user),
      developer: create(:user),
      reporter: create(:user),
      guest: create(:user),
      requester: create(:user)
    }

    group.add_member(members[:owner], GroupMember::OWNER)
    group.add_member(members[:maintainer], GroupMember::MAINTAINER)
    group.add_member(members[:developer], GroupMember::DEVELOPER)
    group.add_member(members[:reporter], GroupMember::REPORTER)
    group.add_member(members[:guest], GroupMember::GUEST)
    group.request_access(members[:requester])

    members
  end

  describe '#web_url' do
    it 'returns the canonical URL' do
      expect(group.web_url).to include("groups/#{group.name}")
    end

    context 'nested group' do
      let(:nested_group) { create(:group, :nested) }

      it { expect(nested_group.web_url).to include("groups/#{nested_group.full_path}") }
    end
  end

  describe 'nested group' do
    subject { build(:group, :nested) }

    it { is_expected.to be_valid }
    it { expect(subject.parent).to be_kind_of(described_class) }
  end

  describe '#max_member_access_for_user' do
    let_it_be(:group_user) { create(:user) }

    context 'with user in the group' do
      before do
        group.add_owner(group_user)
      end

      it 'returns correct access level' do
        expect(group.max_member_access_for_user(group_user)).to eq(Gitlab::Access::OWNER)
      end
    end

    context 'when user is nil' do
      it 'returns NO_ACCESS' do
        expect(group.max_member_access_for_user(nil)).to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    context 'evaluating admin access level' do
      let_it_be(:admin) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns OWNER by default' do
          expect(group.max_member_access_for_user(admin)).to eq(Gitlab::Access::OWNER)
        end
      end

      context 'when admin mode is disabled' do
        it 'returns NO_ACCESS' do
          expect(group.max_member_access_for_user(admin)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end

      it 'returns NO_ACCESS when only concrete membership should be considered' do
        expect(group.max_member_access_for_user(admin, only_concrete_membership: true))
          .to eq(Gitlab::Access::NO_ACCESS)
      end
    end

    context 'group shared with another group' do
      let_it_be(:parent_group_user) { create(:user) }
      let_it_be(:child_group_user) { create(:user) }

      let_it_be(:group_parent) { create(:group, :private) }
      let_it_be(:group) { create(:group, :private, parent: group_parent) }
      let_it_be(:group_child) { create(:group, :private, parent: group) }

      let_it_be(:shared_group_parent) { create(:group, :private) }
      let_it_be(:shared_group) { create(:group, :private, parent: shared_group_parent) }
      let_it_be(:shared_group_child) { create(:group, :private, parent: shared_group) }

      before do
        group_parent.add_owner(parent_group_user)
        group.add_owner(group_user)
        group_child.add_owner(child_group_user)

        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group,
                                    group_access: GroupMember::DEVELOPER })
      end

      context 'with user in the group' do
        it 'returns correct access level' do
          expect(shared_group_parent.max_member_access_for_user(group_user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group.max_member_access_for_user(group_user)).to eq(Gitlab::Access::DEVELOPER)
          expect(shared_group_child.max_member_access_for_user(group_user)).to eq(Gitlab::Access::DEVELOPER)
        end

        context 'with lower group access level than max access level for share' do
          let(:user) { create(:user) }

          it 'returns correct access level' do
            group.add_reporter(user)

            expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
            expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::REPORTER)
            expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::REPORTER)
          end
        end
      end

      context 'with user in the parent group' do
        it 'returns correct access level' do
          expect(shared_group_parent.max_member_access_for_user(parent_group_user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group.max_member_access_for_user(parent_group_user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group_child.max_member_access_for_user(parent_group_user)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end

      context 'with user in the child group' do
        it 'returns correct access level' do
          expect(shared_group_parent.max_member_access_for_user(child_group_user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group.max_member_access_for_user(child_group_user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group_child.max_member_access_for_user(child_group_user)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end

      context 'unrelated project owner' do
        let(:common_id) { [Project.maximum(:id).to_i, Namespace.maximum(:id).to_i].max + 999 }
        let!(:group) { create(:group, id: common_id) }
        let!(:unrelated_project) { create(:project, id: common_id) }
        let(:user) { unrelated_project.first_owner }

        it 'returns correct access level' do
          expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end

      context 'user without accepted access request' do
        let!(:user) { create(:user) }

        before do
          create(:group_member, :developer, :access_request, user: user, group: group)
        end

        it 'returns correct access level' do
          expect(shared_group_parent.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
          expect(shared_group_child.max_member_access_for_user(user)).to eq(Gitlab::Access::NO_ACCESS)
        end
      end
    end

    context 'multiple groups shared with group' do
      let(:user) { create(:user) }
      let(:group) { create(:group, :private) }
      let(:shared_group_parent) { create(:group, :private) }
      let(:shared_group) { create(:group, :private, parent: shared_group_parent) }

      before do
        group.add_owner(user)

        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group,
                                    group_access: GroupMember::DEVELOPER })
        create(:group_group_link, { shared_with_group: group,
                                    shared_group: shared_group_parent,
                                    group_access: GroupMember::MAINTAINER })
      end

      it 'returns correct access level' do
        expect(shared_group.max_member_access_for_user(user)).to eq(Gitlab::Access::MAINTAINER)
      end
    end
  end

  describe '#direct_members' do
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:maintainer) { group.parent.add_member(create(:user), GroupMember::MAINTAINER) }
    let_it_be(:developer) { group.add_member(create(:user), GroupMember::DEVELOPER) }

    it 'does not return members of the parent' do
      expect(group.direct_members).not_to include(maintainer)
    end

    it 'returns the direct member of the group' do
      expect(group.direct_members).to include(developer)
    end

    context 'group sharing' do
      let!(:shared_group) { create(:group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
      end

      it 'does not return members of the shared_with group' do
        expect(shared_group.direct_members).not_to(
          include(developer))
      end
    end
  end

  shared_examples_for 'members_with_parents' do
    let!(:group) { create(:group, :nested) }
    let!(:maintainer) { group.parent.add_member(create(:user), GroupMember::MAINTAINER) }
    let!(:developer) { group.add_member(create(:user), GroupMember::DEVELOPER) }
    let!(:pending_maintainer) { create(:group_member, :awaiting, :maintainer, group: group.parent) }
    let!(:pending_developer) { create(:group_member, :awaiting, :developer, group: group) }

    it 'returns parents active members' do
      expect(group.members_with_parents).to include(developer)
      expect(group.members_with_parents).to include(maintainer)
      expect(group.members_with_parents).not_to include(pending_developer)
      expect(group.members_with_parents).not_to include(pending_maintainer)
    end

    context 'group sharing' do
      let!(:shared_group) { create(:group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
      end

      it 'returns shared with group active members' do
        expect(shared_group.members_with_parents).to(
          include(developer))
        expect(shared_group.members_with_parents).not_to(
          include(pending_developer))
      end
    end
  end

  describe '#members_with_parents' do
    it_behaves_like 'members_with_parents'
  end

  describe '#authorizable_members_with_parents' do
    let(:group) { create(:group) }

    it_behaves_like 'members_with_parents'

    context 'members with associated user but also having invite_token' do
      let!(:member) { create(:group_member, :developer, :invited, user: create(:user), group: group) }

      it 'includes such members in the result' do
        expect(group.authorizable_members_with_parents).to include(member)
      end
    end

    context 'invited members' do
      let!(:member) { create(:group_member, :developer, :invited, group: group) }

      it 'does not include such members in the result' do
        expect(group.authorizable_members_with_parents).not_to include(member)
      end
    end

    context 'members from group shares' do
      let(:shared_group) { group }
      let(:shared_with_group) { create(:group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_group)
      end

      context 'an invited member that is part of the shared_with_group' do
        let!(:member) { create(:group_member, :developer, :invited, group: shared_with_group) }

        it 'does not include such members in the result' do
          expect(shared_group.authorizable_members_with_parents).not_to(
            include(member))
        end
      end
    end
  end

  describe '#members_from_self_and_ancestors_with_effective_access_level' do
    let!(:group_parent) { create(:group, :private) }
    let!(:group) { create(:group, :private, parent: group_parent) }
    let!(:group_child) { create(:group, :private, parent: group) }

    let!(:user) { create(:user) }

    let(:parent_group_access_level) { Gitlab::Access::REPORTER }
    let(:group_access_level) { Gitlab::Access::DEVELOPER }
    let(:child_group_access_level) { Gitlab::Access::MAINTAINER }

    before do
      create(:group_member, user: user, group: group_parent, access_level: parent_group_access_level)
      create(:group_member, user: user, group: group, access_level: group_access_level)
      create(:group_member, :minimal_access, user: create(:user), source: group)
      create(:group_member, user: user, group: group_child, access_level: child_group_access_level)
    end

    it 'returns effective access level for user' do
      expect(group_parent.members_from_self_and_ancestors_with_effective_access_level.as_json).to(
        contain_exactly(
          hash_including('user_id' => user.id, 'access_level' => parent_group_access_level)
        )
      )
      expect(group.members_from_self_and_ancestors_with_effective_access_level.as_json).to(
        contain_exactly(
          hash_including('user_id' => user.id, 'access_level' => group_access_level)
        )
      )
      expect(group_child.members_from_self_and_ancestors_with_effective_access_level.as_json).to(
        contain_exactly(
          hash_including('user_id' => user.id, 'access_level' => child_group_access_level)
        )
      )
    end
  end

  context 'members-related methods' do
    let!(:group) { create(:group, :nested) }
    let!(:sub_group) { create(:group, parent: group) }
    let!(:maintainer) { group.parent.add_member(create(:user), GroupMember::MAINTAINER) }
    let!(:developer) { group.add_member(create(:user), GroupMember::DEVELOPER) }
    let!(:other_developer) { group.add_member(create(:user), GroupMember::DEVELOPER) }

    describe '#direct_and_indirect_members' do
      it 'returns parents members' do
        expect(group.direct_and_indirect_members).to include(developer)
        expect(group.direct_and_indirect_members).to include(maintainer)
      end

      it 'returns descendant members' do
        expect(group.direct_and_indirect_members).to include(other_developer)
      end
    end

    describe '#direct_and_indirect_members_with_inactive' do
      let!(:maintainer_blocked) { group.parent.add_member(create(:user, :blocked), GroupMember::MAINTAINER) }

      it 'returns parents members' do
        expect(group.direct_and_indirect_members_with_inactive).to include(developer)
        expect(group.direct_and_indirect_members_with_inactive).to include(maintainer)
        expect(group.direct_and_indirect_members_with_inactive).to include(maintainer_blocked)
      end

      it 'returns descendant members' do
        expect(group.direct_and_indirect_members_with_inactive).to include(other_developer)
      end
    end
  end

  describe '#users_with_descendants' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }

    it 'returns member users on every nest level without duplication' do
      group.add_developer(user_a)
      nested_group.add_developer(user_b)
      deep_nested_group.add_maintainer(user_a)

      expect(group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(nested_group.users_with_descendants).to contain_exactly(user_a, user_b)
      expect(deep_nested_group.users_with_descendants).to contain_exactly(user_a)
    end
  end

  context 'user-related methods' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }
    let(:user_d) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:project) { create(:project, namespace: group) }

    before do
      group.add_developer(user_a)
      group.add_developer(user_c)
      nested_group.add_developer(user_b)
      deep_nested_group.add_developer(user_a)
      project.add_developer(user_d)
    end

    describe '#direct_and_indirect_users' do
      it 'returns member users on every nest level without duplication' do
        expect(group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c, user_d)
        expect(nested_group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c)
        expect(deep_nested_group.direct_and_indirect_users).to contain_exactly(user_a, user_b, user_c)
      end

      it 'does not return members of projects belonging to ancestor groups' do
        expect(nested_group.direct_and_indirect_users).not_to include(user_d)
      end
    end

    describe '#direct_and_indirect_users_with_inactive' do
      let(:user_blocked_1) { create(:user, :blocked) }
      let(:user_blocked_2) { create(:user, :blocked) }
      let(:user_blocked_3) { create(:user, :blocked) }
      let(:project_in_group) { create(:project, namespace: nested_group) }

      before do
        group.add_developer(user_blocked_1)
        nested_group.add_developer(user_blocked_1)
        deep_nested_group.add_developer(user_blocked_2)
        project_in_group.add_developer(user_blocked_3)
      end

      it 'returns member users on every nest level without duplication' do
        expect(group.direct_and_indirect_users_with_inactive).to contain_exactly(user_a, user_b, user_c, user_d, user_blocked_1, user_blocked_2, user_blocked_3)
        expect(nested_group.direct_and_indirect_users_with_inactive).to contain_exactly(user_a, user_b, user_c, user_blocked_1, user_blocked_2, user_blocked_3)
        expect(deep_nested_group.direct_and_indirect_users_with_inactive).to contain_exactly(user_a, user_b, user_c, user_blocked_1, user_blocked_2)
      end

      it 'returns members of projects belonging to group' do
        expect(nested_group.direct_and_indirect_users_with_inactive).to include(user_blocked_3)
      end
    end
  end

  describe '#project_users_with_descendants' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }

    let(:group) { create(:group) }
    let(:nested_group) { create(:group, parent: group) }
    let(:deep_nested_group) { create(:group, parent: nested_group) }
    let(:project_a) { create(:project, namespace: group) }
    let(:project_b) { create(:project, namespace: nested_group) }
    let(:project_c) { create(:project, namespace: deep_nested_group) }

    it 'returns members of all projects in group and subgroups' do
      project_a.add_developer(user_a)
      project_b.add_developer(user_b)
      project_c.add_developer(user_c)

      expect(group.project_users_with_descendants).to contain_exactly(user_a, user_b, user_c)
      expect(nested_group.project_users_with_descendants).to contain_exactly(user_b, user_c)
      expect(deep_nested_group.project_users_with_descendants).to contain_exactly(user_c)
    end
  end

  describe '#refresh_members_authorized_projects' do
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:parent_group_user) { create(:user) }
    let_it_be(:group_user) { create(:user) }

    before do
      group.parent.add_maintainer(parent_group_user)
      group.add_developer(group_user)
    end

    context 'users for which authorizations refresh is executed' do
      it 'processes authorizations refresh for all members of the group' do
        expect(UserProjectAccessChangedService).to receive(:new).with(contain_exactly(group_user.id, parent_group_user.id)).and_call_original

        group.refresh_members_authorized_projects
      end

      context 'when explicitly specified to run only for direct members' do
        it 'processes authorizations refresh only for direct members of the group' do
          expect(UserProjectAccessChangedService).to receive(:new).with(contain_exactly(group_user.id)).and_call_original

          group.refresh_members_authorized_projects(direct_members_only: true)
        end
      end
    end
  end

  describe '#users_ids_of_direct_members' do
    let_it_be(:group) { create(:group, :nested) }
    let_it_be(:parent_group_user) { create(:user) }
    let_it_be(:group_user) { create(:user) }

    before do
      group.parent.add_maintainer(parent_group_user)
      group.add_developer(group_user)
    end

    it 'does not return user ids of the members of the parent' do
      expect(group.users_ids_of_direct_members).not_to include(parent_group_user.id)
    end

    it 'returns the user ids of the direct member of the group' do
      expect(group.users_ids_of_direct_members).to include(group_user.id)
    end

    context 'group sharing' do
      let!(:shared_group) { create(:group) }

      before do
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
      end

      it 'does not return the user ids of members of the shared_with group' do
        expect(shared_group.users_ids_of_direct_members).not_to(
          include(group_user.id))
      end
    end
  end

  describe '#user_ids_for_project_authorizations' do
    it 'returns the user IDs for which to refresh authorizations' do
      maintainer = create(:user)
      developer = create(:user)

      group.add_member(maintainer, GroupMember::MAINTAINER)
      group.add_member(developer, GroupMember::DEVELOPER)

      expect(group.user_ids_for_project_authorizations)
        .to include(maintainer.id, developer.id)
    end

    context 'group sharing' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group_user) { create(:user) }
      let_it_be(:shared_group) { create(:group) }

      before do
        group.add_developer(group_user)
        create(:group_group_link, shared_group: shared_group, shared_with_group: group)
      end

      it 'returns the user IDs for shared with group members' do
        expect(shared_group.user_ids_for_project_authorizations).to(
          include(group_user.id))
      end
    end

    context 'distinct user ids' do
      let_it_be(:subgroup) { create(:group, :nested) }
      let_it_be(:user) { create(:user) }
      let_it_be(:shared_with_group) { create(:group) }
      let_it_be(:other_subgroup_user) { create(:user) }

      before do
        create(:group_group_link, shared_group: subgroup, shared_with_group: shared_with_group)
        subgroup.add_maintainer(other_subgroup_user)

        # `user` is added as a direct member of the parent group, the subgroup
        # and another group shared with the subgroup.
        subgroup.parent.add_maintainer(user)
        subgroup.add_developer(user)
        shared_with_group.add_guest(user)
      end

      it 'returns only distinct user ids of users for which to refresh authorizations' do
        expect(subgroup.user_ids_for_project_authorizations).to(
          contain_exactly(user.id, other_subgroup_user.id))
      end
    end
  end

  describe '#self_and_hierarchy_intersecting_with_user_groups' do
    let_it_be(:user) { create(:user) }
    let(:subject) { group.self_and_hierarchy_intersecting_with_user_groups(user) }

    it 'makes a call to GroupsFinder' do
      expect(GroupsFinder).to receive_message_chain(:new, :execute, :unscope)

      subject
    end

    context 'when the group is private' do
      let_it_be(:group) { create(:group, :private) }

      context 'when the user is not a member of the group' do
        it 'is an empty array' do
          expect(subject).to eq([])
        end
      end

      context 'when the user is a member of the group' do
        before do
          group.add_developer(user)
        end

        it 'is equal to the group' do
          expect(subject).to match_array([group])
        end
      end

      context 'when the group has a sub group' do
        let_it_be(:subgroup) { create(:group, :private, parent: group) }

        context 'when the user is not a member of the subgroup' do
          it 'is an empty array' do
            expect(subject).to eq([])
          end
        end

        context 'when the user is a member of the subgroup' do
          before do
            subgroup.add_developer(user)
          end

          it 'is equal to the group and subgroup' do
            expect(subject).to match_array([group, subgroup])
          end

          context 'when the group has an ancestor' do
            let_it_be(:ancestor) { create(:group, :private) }

            before do
              group.parent = ancestor
              group.save!
            end

            it 'is equal to the ancestor, group and subgroup' do
              expect(subject).to match_array([ancestor, group, subgroup])
            end
          end
        end
      end
    end

    context 'when the group is public' do
      let_it_be(:group) { create(:group, :public) }

      it 'is equal to the public group regardless of membership' do
        expect(subject).to match_array([group])
      end
    end
  end

  describe '#update_two_factor_requirement_for_members' do
    let_it_be_with_reload(:user) { create(:user) }

    context 'group membership' do
      it 'enables two_factor_requirement for group members' do
        group.add_member(user, GroupMember::OWNER)
        group.update!(require_two_factor_authentication: true)

        group.update_two_factor_requirement_for_members

        expect(user.reload.require_two_factor_authentication_from_group).to be_truthy
      end

      it 'disables two_factor_requirement for group members' do
        user.update!(require_two_factor_authentication_from_group: true)
        group.add_member(user, GroupMember::OWNER)
        group.update!(require_two_factor_authentication: false)

        group.update_two_factor_requirement_for_members

        expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
      end
    end

    context 'sub groups and projects' do
      context 'expanded group members' do
        let(:indirect_user) { create(:user) }

        context 'two_factor_requirement is enabled' do
          context 'two_factor_requirement is also enabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: true)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end

          context 'two_factor_requirement is disabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group, require_two_factor_authentication: true)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: false)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end

            it 'enable two_factor_requirement for ancestor group member' do
              ancestor_group = create(:group)
              ancestor_group.add_member(indirect_user, GroupMember::OWNER)
              group.update!(parent: ancestor_group)
              group.update!(require_two_factor_authentication: true)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end
        end

        context 'two_factor_requirement is disabled' do
          context 'two_factor_requirement is enabled for ancestor group' do
            it 'enables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: true)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_truthy
            end
          end

          context 'two_factor_requirement is also disabled for ancestor group' do
            it 'disables two_factor_requirement for subgroup member' do
              subgroup = create(:group, :nested, parent: group)
              subgroup.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: false)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_falsey
            end

            it 'disables two_factor_requirement for ancestor group member' do
              ancestor_group = create(:group, require_two_factor_authentication: false)
              indirect_user.update!(require_two_factor_authentication_from_group: true)
              ancestor_group.add_member(indirect_user, GroupMember::OWNER)
              group.update!(require_two_factor_authentication: false)

              group.update_two_factor_requirement_for_members

              expect(indirect_user.reload.require_two_factor_authentication_from_group).to be_falsey
            end
          end
        end
      end

      context 'project members' do
        it 'does not enable two_factor_requirement for child project member' do
          project = create(:project, group: group)
          project.add_maintainer(user)
          group.update!(require_two_factor_authentication: true)

          group.update_two_factor_requirement_for_members

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end

        it 'does not enable two_factor_requirement for subgroup child project member' do
          subgroup = create(:group, :nested, parent: group)
          project = create(:project, group: subgroup)
          project.add_maintainer(user)
          group.update!(require_two_factor_authentication: true)

          group.update_two_factor_requirement_for_members

          expect(user.reload.require_two_factor_authentication_from_group).to be_falsey
        end
      end
    end
  end

  describe '#update_two_factor_requirement' do
    it 'enqueues a job when require_two_factor_authentication is changed' do
      expect(Groups::UpdateTwoFactorRequirementForMembersWorker).to receive(:perform_async).with(group.id)

      group.update!(require_two_factor_authentication: true)
    end

    it 'enqueues a job when two_factor_grace_period is changed' do
      expect(Groups::UpdateTwoFactorRequirementForMembersWorker).to receive(:perform_async).with(group.id)

      group.update!(two_factor_grace_period: 23)
    end

    it 'does not enqueue a job when other attributes are changed' do
      expect(Groups::UpdateTwoFactorRequirementForMembersWorker).not_to receive(:perform_async).with(group.id)

      group.update!(description: 'foobar')
    end
  end

  describe '#path_changed_hook' do
    let(:system_hook_service) { SystemHooksService.new }

    context 'for a new group' do
      let(:group) { build(:group) }

      before do
        expect(group).to receive(:system_hook_service).and_return(system_hook_service)
      end

      it 'does not trigger system hook' do
        expect(system_hook_service).to receive(:execute_hooks_for).with(group, :create)

        group.save!
      end
    end

    context 'for an existing group' do
      let(:group) { create(:group, path: 'old-path') }

      context 'when the path is changed' do
        let(:new_path) { 'very-new-path' }

        it 'triggers the rename system hook' do
          expect(group).to receive(:system_hook_service).and_return(system_hook_service)
          expect(system_hook_service).to receive(:execute_hooks_for).with(group, :rename)

          group.update!(path: new_path)
        end
      end

      context 'when the path is not changed' do
        it 'does not trigger system hook' do
          expect(group).not_to receive(:system_hook_service)

          group.update!(name: 'new name')
        end
      end
    end
  end

  describe '#highest_group_member' do
    let(:nested_group) { create(:group, parent: group) }
    let(:nested_group_2) { create(:group, parent: nested_group) }
    let(:user) { create(:user) }

    subject(:highest_group_member) { nested_group_2.highest_group_member(user) }

    context 'when the user is not a member of any group in the hierarchy' do
      it 'returns nil' do
        expect(highest_group_member).to be_nil
      end
    end

    context 'when the user is only a member of one group in the hierarchy' do
      before do
        nested_group.add_developer(user)
      end

      it 'returns that group member' do
        expect(highest_group_member.access_level).to eq(Gitlab::Access::DEVELOPER)
      end
    end

    context 'when the user is a member of several groups in the hierarchy' do
      before do
        group.add_owner(user)
        nested_group.add_developer(user)
        nested_group_2.add_maintainer(user)
      end

      it 'returns the group member with the highest access level' do
        expect(highest_group_member.access_level).to eq(Gitlab::Access::OWNER)
      end
    end
  end

  describe '#bots' do
    subject { group.bots }

    let_it_be(:group) { create(:group) }
    let_it_be(:project_bot) { create(:user, :project_bot) }
    let_it_be(:user) { create(:user) }

    before_all do
      [project_bot, user].each do |member|
        group.add_maintainer(member)
      end
    end

    it { is_expected.to contain_exactly(project_bot) }
    it { is_expected.not_to include(user) }
  end

  describe '#related_group_ids' do
    let(:nested_group) { create(:group, parent: group) }
    let(:shared_with_group) { create(:group, parent: group) }

    before do
      create(:group_group_link, shared_group: nested_group, shared_with_group: shared_with_group)
    end

    subject(:related_group_ids) { nested_group.related_group_ids }

    it 'returns id' do
      expect(related_group_ids).to include(nested_group.id)
    end

    it 'returns ancestor id' do
      expect(related_group_ids).to include(group.id)
    end

    it 'returns shared with group id' do
      expect(related_group_ids).to include(shared_with_group.id)
    end

    context 'with more than one ancestor group' do
      let(:ancestor_group) { create(:group) }

      before do
        group.update!(parent: ancestor_group)
      end

      it 'returns all ancestor group ids' do
        expect(related_group_ids).to(
          include(group.id, ancestor_group.id))
      end
    end

    context 'with more than one shared with group' do
      let(:another_shared_with_group) { create(:group, parent: group) }

      before do
        create(:group_group_link, shared_group: nested_group, shared_with_group: another_shared_with_group)
      end

      it 'returns all shared with group ids' do
        expect(related_group_ids).to(
          include(shared_with_group.id, another_shared_with_group.id))
      end
    end
  end

  context 'with uploads' do
    it_behaves_like 'model with uploads', true do
      let(:model_object) { create(:group, :with_avatar) }
      let(:upload_attribute) { :avatar }
      let(:uploader_class) { AttachmentUploader }
    end
  end

  describe '#first_auto_devops_config' do
    using RSpec::Parameterized::TableSyntax

    let(:group) { create(:group) }

    subject(:fetch_config) { group.first_auto_devops_config }

    where(:instance_value, :group_value, :config) do
      # Instance level enabled
      true | nil    | { status: true, scope: :instance }
      true | true   | { status: true, scope: :group }
      true | false  | { status: false, scope: :group }

      # Instance level disabled
      false | nil    | { status: false, scope: :instance }
      false | true   | { status: true, scope: :group }
      false | false  | { status: false, scope: :group }
    end

    with_them do
      before do
        stub_application_setting(auto_devops_enabled: instance_value)

        group.update_attribute(:auto_devops_enabled, group_value)
      end

      it { is_expected.to eq(config) }
    end

    context 'with parent groups' do
      let(:parent) { create(:group) }

      where(:instance_value, :parent_value, :group_value, :config) do
        # Instance level enabled
        true | nil   | nil    | { status: true, scope: :instance }
        true | nil   | true   | { status: true, scope: :group }
        true | nil   | false  | { status: false, scope: :group }

        true | true  | nil    | { status: true, scope: :group }
        true | true  | true   | { status: true, scope: :group }
        true | true  | false  | { status: false, scope: :group }

        true | false | nil    | { status: false, scope: :group }
        true | false | true   | { status: true, scope: :group }
        true | false | false  | { status: false, scope: :group }

        # Instance level disable
        false | nil  | nil    | { status: false, scope: :instance }
        false | nil  | true   | { status: true, scope: :group }
        false | nil  | false  | { status: false, scope: :group }

        false | true | nil    | { status: true, scope: :group }
        false | true | true   | { status: true, scope: :group }
        false | true | false  | { status: false, scope: :group }

        false | false | nil   | { status: false, scope: :group }
        false | false | true  | { status: true, scope: :group }
        false | false | false | { status: false, scope: :group }
      end

      with_them do
        def define_cache_expectations(cache_key)
          if group_value.nil?
            expect(Rails.cache).to receive(:fetch).with(start_with(cache_key), expires_in: 1.day)
          else
            expect(Rails.cache).not_to receive(:fetch).with(start_with(cache_key), expires_in: 1.day)
          end
        end

        before do
          stub_application_setting(auto_devops_enabled: instance_value)

          group.update!(
            auto_devops_enabled: group_value,
            parent: parent
          )
          parent.update!(auto_devops_enabled: parent_value)

          group.reload # Reload so we get the populated traversal IDs
        end

        it { is_expected.to eq(config) }

        it 'caches the parent config when group auto_devops_enabled is nil' do
          cache_key = "namespaces:{#{group.traversal_ids.first}}:first_auto_devops_config:#{group.id}"
          define_cache_expectations(cache_key)

          fetch_config
        end
      end

      context 'cache expiration' do
        before do
          group.update!(parent: parent)

          reload_models(parent)
        end

        it 'clears both self and descendant cache when the parent value is updated' do
          expect(Rails.cache).to receive(:delete_multi)
            .with(
              match_array(
                [
                  start_with("namespaces:{#{parent.traversal_ids.first}}:first_auto_devops_config:#{parent.id}"),
                  start_with("namespaces:{#{parent.traversal_ids.first}}:first_auto_devops_config:#{group.id}")
                ])
            )

          parent.update!(auto_devops_enabled: true)
        end

        it 'only clears self cache when there are no dependents' do
          expect(Rails.cache).to receive(:delete_multi)
            .with([start_with("namespaces:{#{group.traversal_ids.first}}:first_auto_devops_config:#{group.id}")])

          group.update!(auto_devops_enabled: true)
        end
      end
    end
  end

  describe '#auto_devops_enabled?' do
    subject { group.auto_devops_enabled? }

    context 'when auto devops is explicitly enabled on group' do
      let(:group) { create(:group, :auto_devops_enabled) }

      it { is_expected.to be_truthy }
    end

    context 'when auto devops is explicitly disabled on group' do
      let(:group) { create(:group, :auto_devops_disabled) }

      it { is_expected.to be_falsy }
    end

    context 'when auto devops is implicitly enabled or disabled' do
      before do
        stub_application_setting(auto_devops_enabled: false)

        group.update!(parent: parent_group)
      end

      context 'when auto devops is enabled on root group' do
        let(:root_group) { create(:group, :auto_devops_enabled) }
        let(:subgroup) { create(:group, parent: root_group) }
        let(:parent_group) { create(:group, parent: subgroup) }

        it { is_expected.to be_truthy }
      end

      context 'when auto devops is disabled on root group' do
        let(:root_group) { create(:group, :auto_devops_disabled) }
        let(:subgroup) { create(:group, parent: root_group) }
        let(:parent_group) { create(:group, parent: subgroup) }

        it { is_expected.to be_falsy }
      end

      context 'when auto devops is disabled on parent group and enabled on root group' do
        let(:root_group) { create(:group, :auto_devops_enabled) }
        let(:parent_group) { create(:group, :auto_devops_disabled, parent: root_group) }

        it { is_expected.to be_falsy }
      end
    end
  end

  describe 'project_creation_level' do
    it 'outputs the default one if it is nil' do
      group = create(:group, project_creation_level: nil)

      expect(group.project_creation_level).to eq(Gitlab::CurrentSettings.default_project_creation)
    end
  end

  describe 'subgroup_creation_level' do
    it 'defaults to maintainers' do
      expect(group.subgroup_creation_level)
        .to eq(Gitlab::Access::MAINTAINER_SUBGROUP_ACCESS)
    end
  end

  describe '#access_request_approvers_to_be_notified' do
    let_it_be(:group) { create(:group, :public) }

    it 'returns a maximum of ten owners of the group in recent_sign_in descending order' do
      limit = 2
      stub_const("Member::ACCESS_REQUEST_APPROVERS_TO_BE_NOTIFIED_LIMIT", limit)
      users = create_list(:user, limit + 1, :with_sign_ins)
      active_owners = users.map do |user|
        create(:group_member, :owner, group: group, user: user)
      end

      active_owners_in_recent_sign_in_desc_order = group.members_and_requesters
                                                        .id_in(active_owners)
                                                        .order_recent_sign_in.limit(limit)

      expect(group.access_request_approvers_to_be_notified).to eq(active_owners_in_recent_sign_in_desc_order)
    end

    it 'returns active, non_invited, non_requested owners of the group' do
      owner = create(:group_member, :owner, source: group)

      create(:group_member, :maintainer, group: group)
      create(:group_member, :owner, :invited, group: group)
      create(:group_member, :owner, :access_request, group: group)
      create(:group_member, :owner, :blocked, group: group)

      expect(group.access_request_approvers_to_be_notified.to_a).to eq([owner])
    end
  end

  describe '.preset_root_ancestor_for' do
    let_it_be(:rootgroup, reload: true) { create(:group) }
    let_it_be(:subgroup, reload: true) { create(:group, parent: rootgroup) }
    let_it_be(:subgroup2, reload: true) { create(:group, parent: subgroup) }

    it 'does noting for single group' do
      expect(subgroup).not_to receive(:self_and_ancestors)

      described_class.preset_root_ancestor_for([subgroup])
    end

    it 'sets the same root_ancestor for multiple groups' do
      expect(subgroup).not_to receive(:self_and_ancestors)
      expect(subgroup2).not_to receive(:self_and_ancestors)

      described_class.preset_root_ancestor_for([rootgroup, subgroup, subgroup2])

      expect(subgroup.root_ancestor).to eq(rootgroup)
      expect(subgroup2.root_ancestor).to eq(rootgroup)
    end
  end

  describe '#update_shared_runners_setting!' do
    context 'enabled' do
      subject { group.update_shared_runners_setting!('enabled') }

      context 'group that its ancestors have shared runners disabled' do
        let_it_be(:parent, reload: true) { create(:group, :shared_runners_disabled) }
        let_it_be(:group, reload: true) { create(:group, :shared_runners_disabled, parent: parent) }
        let_it_be(:project, reload: true) { create(:project, shared_runners_enabled: false, group: group) }

        it 'raises exception' do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Shared runners enabled cannot be enabled because parent group has shared Runners disabled')
        end

        it 'does not enable shared runners' do
          expect do
            begin
              subject
            rescue StandardError
              nil
            end

            parent.reload
            group.reload
            project.reload
          end.to not_change { parent.shared_runners_enabled }
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'root group with shared runners disabled' do
        let_it_be(:group) { create(:group, :shared_runners_disabled) }
        let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let_it_be(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

        it 'enables shared Runners only for itself' do
          expect { subject_and_reload(group, sub_group, project) }
            .to change { group.shared_runners_enabled }.from(false).to(true)
            .and not_change { sub_group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end
    end

    context 'disabled_and_unoverridable' do
      let_it_be(:group) { create(:group) }
      let_it_be(:sub_group) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners, parent: group) }
      let_it_be(:sub_group_2) { create(:group, parent: group) }
      let_it_be(:project) { create(:project, group: group, shared_runners_enabled: true) }
      let_it_be(:project_2) { create(:project, group: sub_group_2, shared_runners_enabled: true) }

      subject { group.update_shared_runners_setting!(Namespace::SR_DISABLED_AND_UNOVERRIDABLE) }

      it 'disables shared Runners for all descendant groups and projects' do
        expect { subject_and_reload(group, sub_group, sub_group_2, project, project_2) }
          .to change { group.shared_runners_enabled }.from(true).to(false)
          .and not_change { group.allow_descendants_override_disabled_shared_runners }
          .and not_change { sub_group.shared_runners_enabled }
          .and change { sub_group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
          .and change { sub_group_2.shared_runners_enabled }.from(true).to(false)
          .and not_change { sub_group_2.allow_descendants_override_disabled_shared_runners }
          .and change { project.shared_runners_enabled }.from(true).to(false)
          .and change { project_2.shared_runners_enabled }.from(true).to(false)
      end

      context 'with override on self' do
        let_it_be(:group) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners) }

        it 'disables it' do
          expect { subject_and_reload(group) }
            .to not_change { group.shared_runners_enabled }
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(true).to(false)
        end
      end
    end

    context 'disabled_and_overridable' do
      subject { group.update_shared_runners_setting!(Namespace::SR_DISABLED_AND_OVERRIDABLE) }

      context 'top level group' do
        let_it_be(:group) { create(:group, :shared_runners_disabled) }
        let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let_it_be(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

        it 'enables allow descendants to override only for itself' do
          expect { subject_and_reload(group, sub_group, project) }
            .to change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { sub_group.allow_descendants_override_disabled_shared_runners }
            .and not_change { sub_group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'group that its ancestors have shared Runners disabled but allows to override' do
        let_it_be(:parent) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners) }
        let_it_be(:group) { create(:group, :shared_runners_disabled, parent: parent) }
        let_it_be(:project) { create(:project, shared_runners_enabled: false, group: group) }

        it 'enables allow descendants to override' do
          expect { subject_and_reload(parent, group, project) }
            .to not_change { parent.allow_descendants_override_disabled_shared_runners }
            .and not_change { parent.shared_runners_enabled }
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'when parent does not allow' do
        let_it_be(:parent, reload: true) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false) }
        let_it_be(:group, reload: true) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent: parent) }

        it 'raises exception' do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Allow descendants override disabled shared runners cannot be enabled because parent group does not allow it')
        end

        it 'does not allow descendants to override' do
          expect do
            begin
              subject
            rescue StandardError
              nil
            end

            parent.reload
            group.reload
          end.to not_change { parent.allow_descendants_override_disabled_shared_runners }
            .and not_change { parent.shared_runners_enabled }
            .and not_change { group.allow_descendants_override_disabled_shared_runners }
            .and not_change { group.shared_runners_enabled }
        end
      end

      context 'top level group that has shared Runners enabled' do
        let_it_be(:group) { create(:group, shared_runners_enabled: true) }
        let_it_be(:sub_group) { create(:group, shared_runners_enabled: true, parent: group) }
        let_it_be(:project) { create(:project, shared_runners_enabled: true, group: sub_group) }

        it 'enables allow descendants to override & disables shared runners everywhere' do
          expect { subject_and_reload(group, sub_group, project) }
            .to change { group.shared_runners_enabled }.from(true).to(false)
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and change { sub_group.shared_runners_enabled }.from(true).to(false)
            .and change { project.shared_runners_enabled }.from(true).to(false)
        end
      end
    end

    context 'disabled_with_override (deprecated)' do
      subject { group.update_shared_runners_setting!(Namespace::SR_DISABLED_WITH_OVERRIDE) }

      context 'top level group' do
        let_it_be(:group) { create(:group, :shared_runners_disabled) }
        let_it_be(:sub_group) { create(:group, :shared_runners_disabled, parent: group) }
        let_it_be(:project) { create(:project, shared_runners_enabled: false, group: sub_group) }

        it 'enables allow descendants to override only for itself' do
          expect { subject_and_reload(group, sub_group, project) }
            .to change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { sub_group.allow_descendants_override_disabled_shared_runners }
            .and not_change { sub_group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'group that its ancestors have shared Runners disabled but allows to override' do
        let_it_be(:parent) { create(:group, :shared_runners_disabled, :allow_descendants_override_disabled_shared_runners) }
        let_it_be(:group) { create(:group, :shared_runners_disabled, parent: parent) }
        let_it_be(:project) { create(:project, shared_runners_enabled: false, group: group) }

        it 'enables allow descendants to override' do
          expect { subject_and_reload(parent, group, project) }
            .to not_change { parent.allow_descendants_override_disabled_shared_runners }
            .and not_change { parent.shared_runners_enabled }
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and not_change { group.shared_runners_enabled }
            .and not_change { project.shared_runners_enabled }
        end
      end

      context 'when parent does not allow' do
        let_it_be(:parent, reload: true) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false) }
        let_it_be(:group, reload: true) { create(:group, :shared_runners_disabled, allow_descendants_override_disabled_shared_runners: false, parent: parent) }

        it 'raises exception' do
          expect { subject }
            .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Allow descendants override disabled shared runners cannot be enabled because parent group does not allow it')
        end

        it 'does not allow descendants to override' do
          expect do
            begin
              subject
            rescue StandardError
              nil
            end

            parent.reload
            group.reload
          end.to not_change { parent.allow_descendants_override_disabled_shared_runners }
            .and not_change { parent.shared_runners_enabled }
            .and not_change { group.allow_descendants_override_disabled_shared_runners }
            .and not_change { group.shared_runners_enabled }
        end
      end

      context 'top level group that has shared Runners enabled' do
        let_it_be(:group) { create(:group, shared_runners_enabled: true) }
        let_it_be(:sub_group) { create(:group, shared_runners_enabled: true, parent: group) }
        let_it_be(:project) { create(:project, shared_runners_enabled: true, group: sub_group) }

        it 'enables allow descendants to override & disables shared runners everywhere' do
          expect { subject_and_reload(group, sub_group, project) }
            .to change { group.shared_runners_enabled }.from(true).to(false)
            .and change { group.allow_descendants_override_disabled_shared_runners }.from(false).to(true)
            .and change { sub_group.shared_runners_enabled }.from(true).to(false)
            .and change { project.shared_runners_enabled }.from(true).to(false)
        end
      end
    end
  end

  describe "#default_branch_name" do
    context "when group.namespace_settings does not have a default branch name" do
      it "returns nil" do
        expect(group.default_branch_name).to be_nil
      end
    end

    context "when group.namespace_settings has a default branch name" do
      let(:example_branch_name) { "example_branch_name" }

      before do
        allow(group.namespace_settings)
          .to receive(:default_branch_name)
          .and_return(example_branch_name)
      end

      it "returns the default branch name" do
        expect(group.default_branch_name).to eq(example_branch_name)
      end
    end
  end

  describe "#access_level_roles" do
    let(:group) { create(:group) }

    it "returns the correct roles" do
      expect(group.access_level_roles).to eq(
        {
          'Guest' => 10,
          'Reporter' => 20,
          'Developer' => 30,
          'Maintainer' => 40,
          'Owner' => 50
        }
      )
    end
  end

  describe '#membership_locked?' do
    it 'returns false' do
      expect(build(:group)).not_to be_membership_locked
    end
  end

  describe '#first_owner' do
    let(:group) { build(:group) }

    context 'the group has owners' do
      before do
        group.add_owner(create(:user))
        group.add_owner(create(:user))
      end

      it 'is the first owner' do
        expect(group.first_owner)
          .to eq(group.owners.first)
          .and be_a(User)
      end
    end

    context 'the group has a parent' do
      let(:parent) { build(:group) }

      before do
        group.parent = parent
        parent.add_owner(create(:user))
      end

      it 'is the first owner of the parent' do
        expect(group.first_owner)
          .to eq(parent.first_owner)
          .and be_a(User)
      end
    end

    context 'we fallback to group.owner' do
      before do
        group.owner = build(:user)
      end

      it 'is the group.owner' do
        expect(group.first_owner)
          .to eq(group.owner)
          .and be_a(User)
      end
    end
  end

  describe '#parent_allows_two_factor_authentication?' do
    it 'returns true for top-level group' do
      expect(group.parent_allows_two_factor_authentication?).to eq(true)
    end

    context 'for subgroup' do
      let(:subgroup) { create(:group, parent: group) }

      it 'returns true if parent group allows two factor authentication for its descendants' do
        expect(subgroup.parent_allows_two_factor_authentication?).to eq(true)
      end

      it 'returns true if parent group allows two factor authentication for its descendants' do
        group.namespace_settings.update!(allow_mfa_for_subgroups: false)

        expect(subgroup.parent_allows_two_factor_authentication?).to eq(false)
      end
    end
  end

  describe 'has_project_with_service_desk_enabled?' do
    let_it_be_with_refind(:group) { create(:group, :private) }

    subject { group.has_project_with_service_desk_enabled? }

    before do
      allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(true)
    end

    context 'when service desk is enabled' do
      context 'for top level group' do
        let_it_be(:project) { create(:project, group: group, service_desk_enabled: true) }

        it { is_expected.to eq(true) }

        context 'when service desk is not supported' do
          before do
            allow(Gitlab::ServiceDesk).to receive(:supported?).and_return(false)
          end

          it { is_expected.to eq(false) }
        end
      end

      context 'for subgroup project' do
        let_it_be(:subgroup) { create(:group, :private, parent: group) }
        let_it_be(:project) { create(:project, group: subgroup, service_desk_enabled: true) }

        it { is_expected.to eq(true) }
      end
    end

    context 'when none of group child projects has service desk enabled' do
      let_it_be(:project) { create(:project, group: group, service_desk_enabled: false) }

      before do
        project.update!(service_desk_enabled: false)
      end

      it { is_expected.to eq(false) }
    end
  end

  describe 'with Debian Distributions' do
    subject { create(:group) }

    it_behaves_like 'model with Debian distributions'
  end

  describe '.ids_with_disabled_email' do
    let_it_be(:parent_1) { create(:group, emails_disabled: true) }
    let_it_be(:child_1) { create(:group, parent: parent_1) }

    let_it_be(:parent_2) { create(:group, emails_disabled: false) }
    let_it_be(:child_2) { create(:group, parent: parent_2) }

    let_it_be(:other_group) { create(:group, emails_disabled: false) }

    shared_examples 'returns namespaces with disabled email' do
      subject(:group_ids_where_email_is_disabled) { described_class.ids_with_disabled_email([child_1, child_2, other_group]) }

      it { is_expected.to eq(Set.new([child_1.id])) }
    end

    it_behaves_like 'returns namespaces with disabled email'
  end

  describe '.timelogs' do
    let(:project) { create(:project, namespace: group) }
    let(:issue) { create(:issue, project: project) }
    let(:other_project) { create(:project, namespace: create(:group)) }
    let(:other_issue) { create(:issue, project: other_project) }

    let!(:timelog1) { create(:timelog, issue: issue) }
    let!(:timelog2) { create(:timelog, issue: other_issue) }
    let!(:timelog3) { create(:timelog, issue: issue) }

    it 'returns timelogs belonging to the group' do
      expect(group.timelogs).to contain_exactly(timelog1, timelog3)
    end
  end

  describe '.organizations' do
    it 'returns organizations belonging to the group' do
      crm_organization1 = create(:crm_organization, group: group)
      create(:crm_organization)
      crm_organization3 = create(:crm_organization, group: group)

      expect(group.organizations).to contain_exactly(crm_organization1, crm_organization3)
    end
  end

  describe '.contacts' do
    it 'returns contacts belonging to the group' do
      contact1 = create(:contact, group: group)
      create(:contact)
      contact3 = create(:contact, group: group)

      expect(group.contacts).to contain_exactly(contact1, contact3)
    end
  end

  describe '#to_ability_name' do
    it 'returns group' do
      group = build(:group)

      expect(group.to_ability_name).to eq('group')
    end
  end

  describe '#activity_path' do
    it 'returns the group activity_path' do
      expected_path = "/groups/#{group.name}/-/activity"

      expect(group.activity_path).to eq(expected_path)
    end
  end

  context 'with export' do
    let(:group) { create(:group, :with_export) }

    it '#export_file_exists? returns true' do
      expect(group.export_file_exists?).to be true
    end

    it '#export_archive_exists? returns true' do
      expect(group.export_archive_exists?).to be true
    end
  end

  describe '#open_issues_count', :aggregate_failures do
    let(:group) { build(:group) }

    it 'provides the issue count' do
      expect(group.open_issues_count).to eq 0
    end

    it 'invokes the count service with current_user' do
      user = build(:user)
      count_service = instance_double(Groups::OpenIssuesCountService)
      expect(Groups::OpenIssuesCountService).to receive(:new).with(group, user).and_return(count_service)
      expect(count_service).to receive(:count)

      group.open_issues_count(user)
    end

    it 'invokes the count service with no current_user' do
      count_service = instance_double(Groups::OpenIssuesCountService)
      expect(Groups::OpenIssuesCountService).to receive(:new).with(group, nil).and_return(count_service)
      expect(count_service).to receive(:count)

      group.open_issues_count
    end
  end

  describe '#open_merge_requests_count', :aggregate_failures do
    let(:group) { build(:group) }

    it 'provides the merge request count' do
      expect(group.open_merge_requests_count).to eq 0
    end

    it 'invokes the count service with current_user' do
      user = build(:user)
      count_service = instance_double(Groups::MergeRequestsCountService)
      expect(Groups::MergeRequestsCountService).to receive(:new).with(group, user).and_return(count_service)
      expect(count_service).to receive(:count)

      group.open_merge_requests_count(user)
    end

    it 'invokes the count service with no current_user' do
      count_service = instance_double(Groups::MergeRequestsCountService)
      expect(Groups::MergeRequestsCountService).to receive(:new).with(group, nil).and_return(count_service)
      expect(count_service).to receive(:count)

      group.open_merge_requests_count
    end
  end

  describe '#dependency_proxy_image_prefix' do
    let_it_be(:group) { build_stubbed(:group, path: 'GroupWithUPPERcaseLetters') }

    it 'converts uppercase letters to lowercase' do
      expect(group.dependency_proxy_image_prefix).to end_with("/groupwithuppercaseletters#{DependencyProxy::URL_SUFFIX}")
    end

    it 'removes the protocol' do
      expect(group.dependency_proxy_image_prefix).not_to include('http')
    end

    it 'does not include /groups' do
      expect(group.dependency_proxy_image_prefix).not_to include('/groups')
    end
  end

  describe '#dependency_proxy_image_ttl_policy' do
    subject(:ttl_policy) { group.dependency_proxy_image_ttl_policy }

    it 'builds a new policy if one does not exist', :aggregate_failures do
      expect(ttl_policy.ttl).to eq(90)
      expect(ttl_policy.enabled).to eq(false)
      expect(ttl_policy.created_at).to be_nil
      expect(ttl_policy.updated_at).to be_nil
    end

    context 'with existing policy' do
      before do
        group.dependency_proxy_image_ttl_policy.update!(ttl: 30, enabled: true)
      end

      it 'returns the policy if it already exists', :aggregate_failures do
        expect(ttl_policy.ttl).to eq(30)
        expect(ttl_policy.enabled).to eq(true)
        expect(ttl_policy.created_at).not_to be_nil
        expect(ttl_policy.updated_at).not_to be_nil
      end
    end
  end

  describe '#dependency_proxy_setting' do
    subject(:setting) { group.dependency_proxy_setting }

    it 'builds a new policy if one does not exist', :aggregate_failures do
      expect(setting.enabled).to eq(true)
      expect(setting).not_to be_persisted
    end

    context 'with existing policy' do
      before do
        group.dependency_proxy_setting.update!(enabled: false)
      end

      it 'returns the policy if it already exists', :aggregate_failures do
        expect(setting.enabled).to eq(false)
        expect(setting).to be_persisted
      end
    end
  end

  describe '#crm_enabled?' do
    it 'returns false where no crm_settings exist' do
      expect(group.crm_enabled?).to be_falsey
    end

    it 'returns false where crm_settings.state is disabled' do
      create(:crm_settings, enabled: false, group: group)

      expect(group.crm_enabled?).to be_falsey
    end

    it 'returns true where crm_settings.state is enabled' do
      create(:crm_settings, enabled: true, group: group)

      expect(group.crm_enabled?).to be_truthy
    end

    it 'returns true where crm_settings.state is enabled for subgroup' do
      subgroup = create(:group, :crm_enabled, parent: group)

      expect(subgroup.crm_enabled?).to be_truthy
    end
  end

  describe '.get_ids_by_ids_or_paths' do
    let(:group_path) { 'group_path' }
    let!(:group) { create(:group, path: group_path) }
    let(:group_id) { group.id }

    it 'returns ids matching records based on paths' do
      expect(described_class.get_ids_by_ids_or_paths(nil, [group_path])).to match_array([group_id])
    end

    it 'returns ids matching records based on ids' do
      expect(described_class.get_ids_by_ids_or_paths([group_id], nil)).to match_array([group_id])
    end

    it 'returns ids matching records based on both paths and ids' do
      new_group_id = create(:group).id

      expect(described_class.get_ids_by_ids_or_paths([new_group_id], [group_path])).to match_array([group_id, new_group_id])
    end
  end

  describe '#shared_with_group_links_visible_to_user' do
    let_it_be(:admin) { create :admin }
    let_it_be(:normal_user) { create :user }
    let_it_be(:user_with_access) { create :user }
    let_it_be(:user_with_parent_access) { create :user }
    let_it_be(:user_without_access) { create :user }
    let_it_be(:shared_group) { create :group }
    let_it_be(:parent_group) { create :group, :private }
    let_it_be(:shared_with_private_group) { create :group, :private, parent: parent_group }
    let_it_be(:shared_with_internal_group) { create :group, :internal }
    let_it_be(:shared_with_public_group) { create :group, :public }
    let_it_be(:private_group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_private_group) }
    let_it_be(:internal_group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_internal_group) }
    let_it_be(:public_group_group_link) { create(:group_group_link, shared_group: shared_group, shared_with_group: shared_with_public_group) }

    before do
      shared_with_private_group.add_developer(user_with_access)
      parent_group.add_developer(user_with_parent_access)
    end

    context 'when user is admin', :enable_admin_mode do
      it 'returns all existing shared group links' do
        expect(shared_group.shared_with_group_links_visible_to_user(admin)).to contain_exactly(private_group_group_link, internal_group_group_link, public_group_group_link)
      end
    end

    context 'when user is nil' do
      it 'returns only link of public shared group' do
        expect(shared_group.shared_with_group_links_visible_to_user(nil)).to contain_exactly(public_group_group_link)
      end
    end

    context 'when user has no access to private shared group' do
      it 'returns links of internal and public shared groups' do
        expect(shared_group.shared_with_group_links_visible_to_user(normal_user)).to contain_exactly(internal_group_group_link, public_group_group_link)
      end
    end

    context 'when user is member of private shared group' do
      it 'returns links of private, internal and public shared groups' do
        expect(shared_group.shared_with_group_links_visible_to_user(user_with_access)).to contain_exactly(private_group_group_link, internal_group_group_link, public_group_group_link)
      end
    end

    context 'when user is inherited member of private shared group' do
      it 'returns links of private, internal and public shared groups' do
        expect(shared_group.shared_with_group_links_visible_to_user(user_with_parent_access)).to contain_exactly(private_group_group_link, internal_group_group_link, public_group_group_link)
      end
    end
  end

  describe '#enforced_runner_token_expiration_interval and #effective_runner_token_expiration_interval' do
    shared_examples 'no enforced expiration interval' do
      it { expect(subject.enforced_runner_token_expiration_interval).to be_nil }
    end

    shared_examples 'enforced expiration interval' do |enforced_interval:|
      it { expect(subject.enforced_runner_token_expiration_interval).to eq(enforced_interval) }
    end

    shared_examples 'no effective expiration interval' do
      it { expect(subject.effective_runner_token_expiration_interval).to be_nil }
    end

    shared_examples 'effective expiration interval' do |effective_interval:|
      it { expect(subject.effective_runner_token_expiration_interval).to eq(effective_interval) }
    end

    context 'when there is no interval in group settings' do
      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a group interval' do
      let(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 3.days.to_i) }

      subject { create(:group, namespace_settings: group_settings) }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    # runner_token_expiration_interval should not affect the expiration interval, only
    # group_runner_token_expiration_interval should.
    context 'when there is a site-wide enforced shared interval' do
      before do
        stub_application_setting(runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a site-wide enforced group interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 5.days
    end

    # project_runner_token_expiration_interval should not affect the expiration interval, only
    # group_runner_token_expiration_interval should.
    context 'when there is a site-wide enforced project interval' do
      before do
        stub_application_setting(project_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    # runner_token_expiration_interval should not affect the expiration interval, only
    # subgroup_runner_token_expiration_interval should.
    context 'when there is a grandparent group enforced group interval' do
      let_it_be(:grandparent_group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:grandparent_group) { create(:group, namespace_settings: grandparent_group_settings) }
      let_it_be(:parent_group) { create(:group, parent: grandparent_group) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      subject { subgroup }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a grandparent group enforced subgroup interval' do
      let_it_be(:grandparent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:grandparent_group) { create(:group, namespace_settings: grandparent_group_settings) }
      let_it_be(:parent_group) { create(:group, parent: grandparent_group) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      subject { subgroup }

      it_behaves_like 'enforced expiration interval', enforced_interval: 4.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    # project_runner_token_expiration_interval should not affect the expiration interval, only
    # subgroup_runner_token_expiration_interval should.
    context 'when there is a grandparent group enforced project interval' do
      let_it_be(:grandparent_group_settings) { create(:namespace_settings, project_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:grandparent_group) { create(:group, namespace_settings: grandparent_group_settings) }
      let_it_be(:parent_group) { create(:group, parent: grandparent_group) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      subject { subgroup }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    context 'when there is a parent group enforced interval overridden by group interval' do
      let_it_be(:parent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 5.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }
      let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:subgroup_with_settings) { create(:group, parent: parent_group, namespace_settings: group_settings) }

      subject { subgroup_with_settings }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days

      it 'has human-readable expiration intervals' do
        expect(subject.enforced_runner_token_expiration_interval_human_readable).to eq('5d')
        expect(subject.effective_runner_token_expiration_interval_human_readable).to eq('4d')
      end
    end

    context 'when site-wide enforced interval overrides group interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 3.days.to_i)
      end

      let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group_with_settings) { create(:group, namespace_settings: group_settings) }

      subject { group_with_settings }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when group interval overrides site-wide enforced interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:group_settings) { create(:namespace_settings, runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:group_with_settings) { create(:group, namespace_settings: group_settings) }

      subject { group_with_settings }

      it_behaves_like 'enforced expiration interval', enforced_interval: 5.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    context 'when site-wide enforced interval overrides parent group enforced interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 3.days.to_i)
      end

      let_it_be(:parent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      subject { subgroup }

      it_behaves_like 'enforced expiration interval', enforced_interval: 3.days
      it_behaves_like 'effective expiration interval', effective_interval: 3.days
    end

    context 'when parent group enforced interval overrides site-wide enforced interval' do
      before do
        stub_application_setting(group_runner_token_expiration_interval: 5.days.to_i)
      end

      let_it_be(:parent_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:parent_group) { create(:group, namespace_settings: parent_group_settings) }
      let_it_be(:subgroup) { create(:group, parent: parent_group) }

      subject { subgroup }

      it_behaves_like 'enforced expiration interval', enforced_interval: 4.days
      it_behaves_like 'effective expiration interval', effective_interval: 4.days
    end

    # Unrelated groups should not affect the expiration interval.
    context 'when there is an enforced group interval in an unrelated group' do
      let_it_be(:unrelated_group_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:unrelated_group) { create(:group, namespace_settings: unrelated_group_settings) }
      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end

    # Subgroups should not affect the parent group expiration interval.
    context 'when there is an enforced group interval in a subgroup' do
      let_it_be(:subgroup_settings) { create(:namespace_settings, subgroup_runner_token_expiration_interval: 4.days.to_i) }
      let_it_be(:subgroup) { create(:group, parent: group, namespace_settings: subgroup_settings) }
      let_it_be(:group) { create(:group) }

      subject { group }

      it_behaves_like 'no enforced expiration interval'
      it_behaves_like 'no effective expiration interval'
    end
  end

  describe '#content_editor_on_issues_feature_flag_enabled?' do
    it_behaves_like 'checks self and root ancestor feature flag' do
      let(:feature_flag) { :content_editor_on_issues }
      let(:feature_flag_method) { :content_editor_on_issues_feature_flag_enabled? }
    end
  end

  describe '#work_items_feature_flag_enabled?' do
    it_behaves_like 'checks self and root ancestor feature flag' do
      let(:feature_flag) { :work_items }
      let(:feature_flag_method) { :work_items_feature_flag_enabled? }
    end
  end

  describe '#work_items_mvc_feature_flag_enabled?' do
    it_behaves_like 'checks self and root ancestor feature flag' do
      let(:feature_flag) { :work_items_mvc }
      let(:feature_flag_method) { :work_items_mvc_feature_flag_enabled? }
    end
  end

  describe '#work_items_mvc_2_feature_flag_enabled?' do
    it_behaves_like 'checks self and root ancestor feature flag' do
      let(:feature_flag) { :work_items_mvc_2 }
      let(:feature_flag_method) { :work_items_mvc_2_feature_flag_enabled? }
    end
  end

  describe 'group shares' do
    let!(:sub_group) { create(:group, parent: group) }
    let!(:sub_sub_group) { create(:group, parent: sub_group) }
    let!(:shared_group_1) { create(:group) }
    let!(:shared_group_2) { create(:group) }
    let!(:shared_group_3) { create(:group) }

    before do
      group.shared_with_groups << shared_group_1
      sub_group.shared_with_groups << shared_group_2
      sub_sub_group.shared_with_groups << shared_group_3
    end

    describe '#shared_with_group_links.of_ancestors' do
      using RSpec::Parameterized::TableSyntax

      where(:subject_group, :result) do
        ref(:group)         | []
        ref(:sub_group)     | lazy { [shared_group_1].map(&:id) }
        ref(:sub_sub_group) | lazy { [shared_group_1, shared_group_2].map(&:id) }
      end

      with_them do
        it 'returns correct group shares' do
          expect(subject_group.shared_with_group_links.of_ancestors.map(&:shared_with_group_id)).to match_array(result)
        end
      end
    end

    describe '#shared_with_group_links.of_ancestors_and_self' do
      using RSpec::Parameterized::TableSyntax

      where(:subject_group, :result) do
        ref(:group)         | lazy { [shared_group_1].map(&:id) }
        ref(:sub_group)     | lazy { [shared_group_1, shared_group_2].map(&:id) }
        ref(:sub_sub_group) | lazy { [shared_group_1, shared_group_2, shared_group_3].map(&:id) }
      end

      with_them do
        it 'returns correct group shares' do
          expect(subject_group.shared_with_group_links.of_ancestors_and_self.map(&:shared_with_group_id)).to match_array(result)
        end
      end
    end
  end

  describe '#packages_policy_subject' do
    it 'returns wrapper' do
      expect(group.packages_policy_subject).to be_a(Packages::Policies::Group)
      expect(group.packages_policy_subject.group).to eq(group)
    end
  end

  describe '#gitlab_deploy_token' do
    subject(:gitlab_deploy_token) { group.gitlab_deploy_token }

    context 'when there is a gitlab deploy token associated' do
      let!(:deploy_token) { create(:deploy_token, :group, :gitlab_deploy_token, groups: [group]) }

      it { is_expected.to eq(deploy_token) }
    end

    context 'when there is no a gitlab deploy token associated' do
      it { is_expected.to be_nil }
    end

    context 'when there is a gitlab deploy token associated but is has been revoked' do
      let!(:deploy_token) { create(:deploy_token, :group, :gitlab_deploy_token, :revoked, groups: [group]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a gitlab deploy token associated but it is expired' do
      let!(:deploy_token) { create(:deploy_token, :group, :gitlab_deploy_token, :expired, groups: [group]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a deploy token associated with a different name' do
      let!(:deploy_token) { create(:deploy_token, :group, groups: [group]) }

      it { is_expected.to be_nil }
    end

    context 'when there is a gitlab deploy token associated to a different group' do
      let!(:deploy_token) { create(:deploy_token, :group, :gitlab_deploy_token, groups: [create(:group)]) }

      it { is_expected.to be_nil }
    end
  end

  describe '#usage_quotas_enabled?', feature_category: :consumables_cost_management, unless: Gitlab.ee? do
    using RSpec::Parameterized::TableSyntax

    where(:feature_enabled, :root_group, :result) do
      false | true  | false
      false | false | false
      true  | false | false
      true  | true  | true
    end

    with_them do
      before do
        stub_feature_flags(usage_quotas_for_all_editions: feature_enabled)
        allow(group).to receive(:root?).and_return(root_group)
      end

      it 'returns the expected result' do
        expect(group.usage_quotas_enabled?).to eq result
      end
    end
  end

  describe '#readme_project' do
    it 'returns groups project containing metadata' do
      readme_project = create(:project, path: Group::README_PROJECT_PATH, namespace: group)
      create(:project, namespace: group)

      expect(group.readme_project).to eq(readme_project)
    end
  end

  describe '#group_readme' do
    it 'returns readme from group readme project' do
      create(:project, :repository, path: Group::README_PROJECT_PATH, namespace: group)

      expect(group.group_readme.name).to eq('README.md')
      expect(group.group_readme.data).to include('testme')
    end

    it 'returns nil if no readme project is present' do
      create(:project, :repository, namespace: group)

      expect(group.group_readme).to be(nil)
    end
  end
end
