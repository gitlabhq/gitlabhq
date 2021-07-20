# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::CreateService, '#execute' do
  let!(:user) { create(:user) }
  let!(:group_params) { { path: "group_path", visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

  subject { service.execute }

  describe 'visibility level restrictions' do
    let!(:service) { described_class.new(user, group_params) }

    context "create groups without restricted visibility level" do
      it { is_expected.to be_persisted }
    end

    context "cannot create group with restricted visibility level" do
      before do
        allow_any_instance_of(ApplicationSetting).to receive(:restricted_visibility_levels).and_return([Gitlab::VisibilityLevel::PUBLIC])
      end

      it { is_expected.not_to be_persisted }
    end
  end

  context 'creating a group with `default_branch_protection` attribute' do
    let(:params) { group_params.merge(default_branch_protection: Gitlab::Access::PROTECTION_NONE) }
    let(:service) { described_class.new(user, params) }
    let(:created_group) { service.execute }

    context 'for users who have the ability to create a group with `default_branch_protection`' do
      it 'creates group with the specified branch protection level' do
        expect(created_group.default_branch_protection).to eq(Gitlab::Access::PROTECTION_NONE)
      end
    end

    context 'for users who do not have the ability to create a group with `default_branch_protection`' do
      it 'does not create the group with the specified branch protection level' do
        allow(Ability).to receive(:allowed?).and_call_original
        allow(Ability).to receive(:allowed?).with(user, :create_group_with_default_branch_protection) { false }

        expect(created_group.default_branch_protection).not_to eq(Gitlab::Access::PROTECTION_NONE)
      end
    end
  end

  context 'creating a group with `allow_mfa_for_subgroups` attribute' do
    let(:params) { group_params.merge(allow_mfa_for_subgroups: false) }
    let(:service) { described_class.new(user, params) }

    it 'creates group without error' do
      expect(service.execute).to be_persisted
    end
  end

  describe 'creating a top level group' do
    let(:service) { described_class.new(user, group_params) }

    context 'when user can create a group' do
      before do
        user.update_attribute(:can_create_group, true)
      end

      it { is_expected.to be_persisted }

      it 'adds an onboarding progress record' do
        expect { subject }.to change(OnboardingProgress, :count).from(0).to(1)
      end
    end

    context 'when user can not create a group' do
      before do
        user.update_attribute(:can_create_group, false)
      end

      it { is_expected.not_to be_persisted }
    end
  end

  describe 'creating subgroup' do
    let!(:group) { create(:group) }
    let!(:service) { described_class.new(user, group_params.merge(parent_id: group.id)) }

    context 'as group owner' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to be_persisted }

      it 'does not add an onboarding progress record' do
        expect { subject }.not_to change(OnboardingProgress, :count).from(0)
      end
    end

    context 'as guest' do
      it 'does not save group and returns an error' do
        is_expected.not_to be_persisted

        expect(subject.errors[:parent_id].first).to eq(s_('CreateGroup|You don’t have permission to create a subgroup in this group.'))
        expect(subject.parent_id).to be_nil
      end
    end

    context 'as owner' do
      before do
        group.add_owner(user)
      end

      it { is_expected.to be_persisted }
    end

    context 'as maintainer' do
      before do
        group.add_maintainer(user)
      end

      it { is_expected.to be_persisted }
    end
  end

  describe "when visibility level is passed as a string" do
    let(:service) { described_class.new(user, group_params) }
    let(:group_params) { { path: 'group_path', visibility: 'public' } }

    it "assigns the correct visibility level" do
      group = service.execute

      expect(group.visibility_level).to eq(Gitlab::VisibilityLevel::PUBLIC)
    end
  end

  describe 'creating a mattermost team' do
    let!(:params) { group_params.merge(create_chat_team: "true") }
    let!(:service) { described_class.new(user, params) }

    before do
      stub_mattermost_setting(enabled: true)
    end

    it 'create the chat team with the group' do
      allow_any_instance_of(::Mattermost::Team).to receive(:create)
        .and_return({ 'name' => 'tanuki', 'id' => 'lskdjfwlekfjsdifjj' })

      expect { subject }.to change { ChatTeam.count }.from(0).to(1)
    end
  end

  describe 'creating a setting record' do
    let(:service) { described_class.new(user, group_params) }

    it 'create the settings record connected to the group' do
      group = subject
      expect(group.namespace_settings).to be_persisted
    end
  end

  describe 'create service for the group' do
    let(:service) { described_class.new(user, group_params) }
    let(:created_group) { service.execute }

    context 'with an active instance-level integration' do
      let!(:instance_integration) { create(:prometheus_integration, :instance, api_url: 'https://prometheus.instance.com/') }

      it 'creates a service from the instance-level integration' do
        expect(created_group.integrations.count).to eq(1)
        expect(created_group.integrations.first.api_url).to eq(instance_integration.api_url)
        expect(created_group.integrations.first.inherit_from_id).to eq(instance_integration.id)
      end

      context 'with an active group-level integration' do
        let(:service) { described_class.new(user, group_params.merge(parent_id: group.id)) }
        let!(:group_integration) { create(:prometheus_integration, group: group, project: nil, api_url: 'https://prometheus.group.com/') }
        let(:group) do
          create(:group).tap do |group|
            group.add_owner(user)
          end
        end

        it 'creates a service from the group-level integration' do
          expect(created_group.integrations.count).to eq(1)
          expect(created_group.integrations.first.api_url).to eq(group_integration.api_url)
          expect(created_group.integrations.first.inherit_from_id).to eq(group_integration.id)
        end

        context 'with an active subgroup' do
          let(:service) { described_class.new(user, group_params.merge(parent_id: subgroup.id)) }
          let!(:subgroup_integration) { create(:prometheus_integration, group: subgroup, project: nil, api_url: 'https://prometheus.subgroup.com/') }
          let(:subgroup) do
            create(:group, parent: group).tap do |subgroup|
              subgroup.add_owner(user)
            end
          end

          it 'creates a service from the subgroup-level integration' do
            expect(created_group.integrations.count).to eq(1)
            expect(created_group.integrations.first.api_url).to eq(subgroup_integration.api_url)
            expect(created_group.integrations.first.inherit_from_id).to eq(subgroup_integration.id)
          end
        end
      end
    end
  end

  context 'shared runners configuration' do
    context 'parent group present' do
      using RSpec::Parameterized::TableSyntax

      where(:shared_runners_config, :descendants_override_disabled_shared_runners_config) do
        true  | false
        false | false
        # true  | true # invalid at the group level, leaving as comment to make explicit
        false | true
      end

      with_them do
        let!(:group) { create(:group, shared_runners_enabled: shared_runners_config, allow_descendants_override_disabled_shared_runners: descendants_override_disabled_shared_runners_config) }
        let!(:service) { described_class.new(user, group_params.merge(parent_id: group.id)) }

        before do
          group.add_owner(user)
        end

        it 'creates group following the parent config' do
          new_group = service.execute

          expect(new_group.shared_runners_enabled).to eq(shared_runners_config)
          expect(new_group.allow_descendants_override_disabled_shared_runners).to eq(descendants_override_disabled_shared_runners_config)
        end
      end
    end

    context 'root group' do
      let!(:service) { described_class.new(user) }

      it 'follows default config' do
        new_group = service.execute

        expect(new_group.shared_runners_enabled).to eq(true)
        expect(new_group.allow_descendants_override_disabled_shared_runners).to eq(false)
      end
    end
  end
end
