# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobToken::Allowlist, feature_category: :continuous_integration do
  include Ci::JobTokenScopeHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:source_project) { create(:project) }

  let(:allowlist) { described_class.new(source_project, direction: direction) }
  let(:direction) { :outbound }

  describe '#projects' do
    subject(:projects) { allowlist.projects }

    context 'when no projects are added to the scope' do
      [:inbound, :outbound].each do |d|
        context "with #{d}" do
          let(:direction) { d }

          it 'returns the project defining the scope' do
            expect(projects).to contain_exactly(source_project)
          end
        end
      end
    end

    context 'when projects are added to the scope' do
      include_context 'with a project in each allowlist'

      where(:direction, :additional_project) do
        :outbound | ref(:outbound_allowlist_project)
        :inbound  | ref(:inbound_allowlist_project)
      end

      with_them do
        it 'returns all projects that can be accessed from a given scope' do
          expect(projects).to contain_exactly(source_project, additional_project)
        end
      end
    end
  end

  context 'when no groups are added to the scope' do
    subject(:groups) { allowlist.groups }

    it 'returns an empty list' do
      expect(groups).to be_empty
    end
  end

  context 'when groups are added to the scope' do
    subject(:groups) { allowlist.groups }

    let_it_be(:target_group) { create(:group) }

    include_context 'with projects that are with and without groups added in allowlist'

    with_them do
      it 'returns all groups that are allowed access in the job token scope' do
        expect(groups).to contain_exactly(target_group)
      end
    end
  end

  describe 'add!' do
    let_it_be(:added_project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:policies) { %w[read_containers read_packages] }
    let_it_be(:default_permissions) { false }

    subject(:add_project) do
      allowlist.add!(added_project, default_permissions: default_permissions, policies: policies, user: user)
    end

    [true, false].each do |d|
      context "with default permissions #{d}" do
        let_it_be(:default_permissions) { d }

        it "sets default permissions to #{d}" do
          project_link = add_project

          expect(project_link.default_permissions).to eq(default_permissions)
        end
      end
    end

    [:inbound, :outbound].each do |d|
      context "with #{d}" do
        let(:direction) { d }

        it 'adds the project scope link' do
          project_link = add_project

          expect(allowlist.projects).to contain_exactly(source_project, added_project)
          expect(project_link.added_by_id).to eq(user.id)
          expect(project_link.source_project_id).to eq(source_project.id)
          expect(project_link.target_project_id).to eq(added_project.id)
          expect(project_link.job_token_policies).to eq(policies)
        end

        context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
          before do
            stub_feature_flags(add_policies_to_ci_job_token: false)
          end

          it 'adds the project scope link but with empty job token policies' do
            project_link = add_project

            expect(allowlist.projects).to contain_exactly(source_project, added_project)
            expect(project_link.added_by_id).to eq(user.id)
            expect(project_link.source_project_id).to eq(source_project.id)
            expect(project_link.target_project_id).to eq(added_project.id)
            expect(project_link.default_permissions).to be(true)
            expect(project_link.job_token_policies).to eq([])
          end
        end
      end
    end
  end

  describe 'add_group!' do
    let_it_be(:added_group) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:policies) { %w[read_containers read_packages] }
    let_it_be(:default_permissions) { false }

    subject(:add_group) do
      allowlist.add_group!(added_group, default_permissions: default_permissions, policies: policies, user: user)
    end

    [true, false].each do |d|
      context "with default permissions #{d}" do
        let_it_be(:default_permissions) { d }

        it "sets default permissions to #{d}" do
          group_link = add_group

          expect(group_link.default_permissions).to eq(default_permissions)
        end
      end
    end

    it 'adds the group scope link' do
      group_link = add_group

      expect(allowlist.groups).to contain_exactly(added_group)
      expect(group_link.added_by_id).to eq(user.id)
      expect(group_link.source_project_id).to eq(source_project.id)
      expect(group_link.target_group_id).to eq(added_group.id)
      expect(group_link.job_token_policies).to eq(policies)
    end

    context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'adds the group scope link but with empty job token policies' do
        group_link = add_group

        expect(allowlist.groups).to contain_exactly(added_group)
        expect(group_link.added_by_id).to eq(user.id)
        expect(group_link.source_project_id).to eq(source_project.id)
        expect(group_link.target_group_id).to eq(added_group.id)
        expect(group_link.default_permissions).to be(true)
        expect(group_link.job_token_policies).to eq([])
      end
    end
  end

  describe '#includes_project?' do
    subject { allowlist.includes_project?(includes_project) }

    context 'without scoped projects' do
      let(:unscoped_project) { build(:project) }

      where(:includes_project, :direction, :result) do
        ref(:source_project)   | :outbound | false
        ref(:source_project)   | :inbound  | false
        ref(:unscoped_project) | :outbound | false
        ref(:unscoped_project) | :inbound  | false
      end

      with_them do
        it { is_expected.to be result }
      end
    end

    context 'with a project in each allowlist' do
      include_context 'with a project in each allowlist'

      where(:includes_project, :direction, :result) do
        ref(:source_project)          | :outbound | false
        ref(:source_project)          | :inbound  | false
        ref(:inbound_allowlist_project)  | :outbound | false
        ref(:inbound_allowlist_project)  | :inbound  | true
        ref(:outbound_allowlist_project) | :outbound | true
        ref(:outbound_allowlist_project) | :inbound  | false
        ref(:unscoped_project1)       | :outbound | false
        ref(:unscoped_project1)       | :inbound  | false
        ref(:unscoped_project2)       | :outbound | false
        ref(:unscoped_project2)       | :inbound  | false
      end

      with_them do
        it { is_expected.to be result }
      end
    end

    describe '#includes_group' do
      subject { allowlist.includes_group?(target_project) }

      let_it_be(:target_group) { create(:group) }
      let_it_be(:target_project) do
        create(:project,
          ci_inbound_job_token_scope_enabled: true,
          group: target_group
        )
      end

      context 'without scoped groups' do
        let_it_be(:unscoped_project) { build(:project) }

        where(:source_project, :result) do
          ref(:unscoped_project) | false
        end

        with_them do
          it { is_expected.to be result }
        end
      end

      context 'with a group in each allowlist' do
        include_context 'with projects that are with and without groups added in allowlist'

        where(:source_project, :result) do
          ref(:project_with_target_project_group_in_allowlist) | true
          ref(:project_wo_target_project_group_in_allowlist) | false
        end

        with_them do
          it { is_expected.to be result }
        end
      end
    end
  end

  describe '#nearest_scope_for_target_project' do
    subject { allowlist.nearest_scope_for_target_project(target_project) }

    let_it_be(:direction) { :inbound }
    let_it_be(:root_group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: root_group) }
    let_it_be(:target_project) { create(:project, group: subgroup) }

    let!(:scope_by_project) do
      create(:ci_job_token_project_scope_link,
        source_project: source_project,
        target_project: target_project,
        direction: :inbound
      )
    end

    let!(:scope_by_subgroup) do
      create(:ci_job_token_group_scope_link, source_project: source_project, target_group: subgroup)
    end

    let!(:scope_by_root_group) do
      create(:ci_job_token_group_scope_link, source_project: source_project, target_group: root_group)
    end

    context 'when the target project is the nearest association' do
      it { is_expected.to eq scope_by_project }
    end

    context "when the target project's group is the nearest association" do
      let(:scope_by_project) { nil }

      it { is_expected.to eq scope_by_subgroup }
    end

    context "when the target project's root group is the nearest association" do
      let(:scope_by_project) { nil }
      let(:scope_by_subgroup) { nil }

      it { is_expected.to eq scope_by_root_group }
    end

    context 'when the subgroup is transferred to a another newer subgroup and no project scope exists' do
      let_it_be(:another_subgroup) { create(:group, parent: root_group) }

      let(:scope_by_project) { nil }
      let!(:scope_by_another_subgroup) do
        create(:ci_job_token_group_scope_link, source_project: source_project, target_group: another_subgroup)
      end

      before do
        subgroup.update!(parent: another_subgroup)
      end

      it { is_expected.to eq scope_by_subgroup }
    end
  end

  describe '#bulk_add_projects!' do
    let_it_be(:added_project1) { create(:project) }
    let_it_be(:added_project2) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:policies) { %w[read_containers read_packages] }

    subject(:add_projects) do
      allowlist.bulk_add_projects!([added_project1, added_project2], policies: policies, user: user,
        autopopulated: true)
    end

    it 'adds the project scope links' do
      add_projects

      project_links = Ci::JobToken::ProjectScopeLink.where(source_project_id: source_project.id)
      project_link = project_links.first

      expect(allowlist.projects).to match_array([source_project, added_project1, added_project2])
      expect(project_link.added_by_id).to eq(user.id)
      expect(project_link.source_project_id).to eq(source_project.id)
      expect(project_link.target_project_id).to eq(added_project1.id)
      expect(project_link.job_token_policies).to eq(policies)
    end

    context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'adds the project scope link but with empty job token policies' do
        add_projects

        project_links = Ci::JobToken::ProjectScopeLink.where(source_project_id: source_project.id)
        project_link = project_links.first

        expect(allowlist.projects).to match_array([source_project, added_project1, added_project2])
        expect(project_link.added_by_id).to eq(user.id)
        expect(project_link.source_project_id).to eq(source_project.id)
        expect(project_link.target_project_id).to eq(added_project1.id)
        expect(project_link.job_token_policies).to eq([])
      end
    end
  end

  describe '#bulk_add_groups!' do
    let_it_be(:added_group1) { create(:group) }
    let_it_be(:added_group2) { create(:group) }
    let_it_be(:user) { create(:user) }
    let_it_be(:policies) { %w[read_containers read_packages] }

    subject(:add_groups) do
      allowlist.bulk_add_groups!([added_group1, added_group2], policies: policies, user: user, autopopulated: true)
    end

    it 'adds the group scope links' do
      add_groups

      group_links = Ci::JobToken::GroupScopeLink.where(source_project_id: source_project.id)
      group_link = group_links.first

      expect(allowlist.groups).to match_array([added_group1, added_group2])
      expect(group_link.added_by_id).to eq(user.id)
      expect(group_link.source_project_id).to eq(source_project.id)
      expect(group_link.target_group_id).to eq(added_group1.id)
      expect(group_link.job_token_policies).to eq(policies)
      expect(group_link.autopopulated).to be true
    end

    context 'when feature-flag `add_policies_to_ci_job_token` is disabled' do
      before do
        stub_feature_flags(add_policies_to_ci_job_token: false)
      end

      it 'adds the group scope link but with empty job token policies' do
        add_groups

        group_links = Ci::JobToken::GroupScopeLink.where(source_project_id: source_project.id)
        group_link = group_links.first

        expect(allowlist.groups).to match_array([added_group1, added_group2])
        expect(group_link.added_by_id).to eq(user.id)
        expect(group_link.source_project_id).to eq(source_project.id)
        expect(group_link.target_group_id).to eq(added_group1.id)
        expect(group_link.job_token_policies).to eq([])
        expect(group_link.autopopulated).to be true
      end
    end
  end

  describe '#autopopulated_project_global_ids' do
    let!(:project_link1) do
      create(:ci_job_token_project_scope_link, source_project: source_project, autopopulated: true)
    end

    let!(:project_link2) do
      create(:ci_job_token_project_scope_link, source_project: source_project, autopopulated: true)
    end

    let!(:project_link3) do
      create(:ci_job_token_project_scope_link, source_project: source_project)
    end

    it 'returns an array of autopopulated project global ids only' do
      project_global_ids = allowlist.autopopulated_project_global_ids

      expect(project_global_ids.size).to eq 2
      expect(project_global_ids).to contain_exactly(project_link1.target_project.to_global_id,
        project_link2.target_project.to_global_id)
    end
  end

  describe '#autopopulated_group_global_ids' do
    let!(:group_link1) do
      create(:ci_job_token_group_scope_link, source_project: source_project, autopopulated: true)
    end

    let!(:group_link2) do
      create(:ci_job_token_group_scope_link, source_project: source_project, autopopulated: true)
    end

    let!(:group_link3) do
      create(:ci_job_token_group_scope_link, source_project: source_project)
    end

    it 'returns an array of autopopulated group global ids only' do
      group_global_ids = allowlist.autopopulated_group_global_ids

      expect(group_global_ids.size).to eq 2
      expect(group_global_ids).to contain_exactly(group_link1.target_group.to_global_id,
        group_link2.target_group.to_global_id)
    end
  end
end
