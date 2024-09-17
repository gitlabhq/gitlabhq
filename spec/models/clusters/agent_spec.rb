# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agent, feature_category: :deployment_management do
  subject { create(:cluster_agent) }

  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to belong_to(:project).class_name('::Project') }
  it { is_expected.to have_many(:agent_tokens).class_name('Clusters::AgentToken').order(Clusters::AgentToken.arel_table[:last_used_at].desc.nulls_last) }
  it { is_expected.to have_many(:active_agent_tokens).class_name('Clusters::AgentToken').conditions(status: 0).order(Clusters::AgentToken.arel_table[:last_used_at].desc.nulls_last) }
  it { is_expected.to have_many(:ci_access_group_authorizations).class_name('Clusters::Agents::Authorizations::CiAccess::GroupAuthorization') }
  it { is_expected.to have_many(:ci_access_authorized_groups).through(:ci_access_group_authorizations) }
  it { is_expected.to have_many(:ci_access_project_authorizations).class_name('Clusters::Agents::Authorizations::CiAccess::ProjectAuthorization') }
  it { is_expected.to have_many(:ci_access_authorized_projects).through(:ci_access_project_authorizations).class_name('::Project') }
  it { is_expected.to have_many(:environments).class_name('::Environment') }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(63) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }

  describe 'scopes' do
    describe '.ordered_by_name' do
      let(:names) { %w[agent-d agent-b agent-a agent-c] }

      subject { described_class.ordered_by_name }

      before do
        names.each do |name|
          create(:cluster_agent, name: name)
        end
      end

      it { expect(subject.map(&:name)).to eq(names.sort) }
    end

    describe '.with_name' do
      let!(:matching_name) { create(:cluster_agent, name: 'matching-name') }
      let!(:other_name) { create(:cluster_agent, name: 'other-name') }

      subject { described_class.with_name(matching_name.name) }

      it { is_expected.to contain_exactly(matching_name) }
    end

    describe '.has_vulnerabilities' do
      let_it_be(:without_vulnerabilities) { create(:cluster_agent, has_vulnerabilities: false) }
      let_it_be(:with_vulnerabilities) { create(:cluster_agent, has_vulnerabilities: true) }

      context 'when value is not provided' do
        subject { described_class.has_vulnerabilities }

        it 'returns agents which have vulnerabilities' do
          is_expected.to contain_exactly(with_vulnerabilities)
        end
      end

      context 'when value is provided' do
        subject { described_class.has_vulnerabilities(value) }

        context 'as true' do
          let(:value) { true }

          it 'returns agents which have vulnerabilities' do
            is_expected.to contain_exactly(with_vulnerabilities)
          end
        end

        context 'as false' do
          let(:value) { false }

          it 'returns agents which do not have vulnerabilities' do
            is_expected.to contain_exactly(without_vulnerabilities)
          end
        end
      end
    end
  end

  describe 'validation' do
    describe 'name validation' do
      it 'rejects names that do not conform to RFC 1123', :aggregate_failures do
        %w[Agent agentA agentAagain gent- -agent agent.a agent/a agent>a].each do |name|
          agent = build(:cluster_agent, name: name)

          expect(agent).not_to be_valid
          expect(agent.errors[:name]).to eq(["can contain only lowercase letters, digits, and '-', but cannot start or end with '-'"])
        end
      end

      it 'accepts valid names', :aggregate_failures do
        %w[agent agent123 agent-123].each do |name|
          agent = build(:cluster_agent, name: name)

          expect(agent).to be_valid
        end
      end
    end
  end

  describe '#has_access_to?' do
    let(:agent) { build(:cluster_agent) }

    it 'has access to own project' do
      expect(agent.has_access_to?(agent.project)).to be_truthy
    end

    it 'does not have access to other projects' do
      expect(agent.has_access_to?(create(:project))).to be_falsey
    end
  end

  describe '#connected?' do
    let_it_be(:agent) { create(:cluster_agent) }

    let!(:token) { create(:cluster_agent_token, agent: agent, last_used_at: last_used_at) }

    subject { agent.connected? }

    context 'agent has never connected' do
      let(:last_used_at) { nil }

      it { is_expected.to be_falsey }
    end

    context 'agent has connected, but not recently' do
      let(:last_used_at) { 2.hours.ago }

      it { is_expected.to be_falsey }
    end

    context 'agent has connected recently' do
      let(:last_used_at) { 2.minutes.ago }

      it { is_expected.to be_truthy }

      context 'agent token has been revoked' do
        before do
          token.revoked!
        end

        it { is_expected.to be_falsey }
      end
    end

    context 'agent has multiple tokens' do
      let!(:inactive_token) { create(:cluster_agent_token, agent: agent, last_used_at: 2.hours.ago) }
      let(:last_used_at) { 2.minutes.ago }

      it { is_expected.to be_truthy }
    end
  end

  describe '#activity_event_deletion_cutoff' do
    let_it_be(:agent) { create(:cluster_agent) }
    let_it_be(:event1) { create(:agent_activity_event, agent: agent, recorded_at: 1.hour.ago) }
    let_it_be(:event2) { create(:agent_activity_event, agent: agent, recorded_at: 2.hours.ago) }
    let_it_be(:event3) { create(:agent_activity_event, agent: agent, recorded_at: 3.hours.ago) }

    subject { agent.activity_event_deletion_cutoff }

    before do
      stub_const("#{described_class}::ACTIVITY_EVENT_LIMIT", 2)
    end

    it { is_expected.to be_like_time(event2.recorded_at) }
  end

  describe '#ci_access_authorized_for?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:organization) { create(:group) }
    let_it_be(:agent_management_project) { create(:project, group: organization) }
    let_it_be(:agent) { create(:cluster_agent, project: agent_management_project) }
    let_it_be(:deployment_project) { create(:project, group: organization) }

    let(:user) { create(:user) }

    subject { agent.ci_access_authorized_for?(user) }

    it { is_expected.to eq(false) }

    context 'with project-level authorization' do
      let!(:authorization) { create(:agent_ci_access_project_authorization, agent: agent, project: deployment_project) }

      where(:user_role, :allowed) do
        :guest       | false
        :reporter    | false
        :developer   | true
        :maintainer  | true
        :owner       | true
      end

      with_them do
        before do
          deployment_project.add_member(user, user_role)
        end

        it { is_expected.to eq(allowed) }
      end
    end

    context 'with group-level authorization' do
      let!(:authorization) { create(:agent_ci_access_group_authorization, agent: agent, group: organization) }

      where(:user_role, :allowed) do
        :guest       | false
        :reporter    | false
        :developer   | true
        :maintainer  | true
        :owner       | true
      end

      with_them do
        before do
          organization.add_member(user, user_role)
        end

        it { is_expected.to eq(allowed) }
      end
    end
  end

  describe '#user_access_authorized_for?' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:organization) { create(:group) }
    let_it_be(:agent_management_project) { create(:project, group: organization) }
    let_it_be(:agent) { create(:cluster_agent, project: agent_management_project) }
    let_it_be(:deployment_project) { create(:project, group: organization) }

    let(:user) { create(:user) }

    subject { agent.user_access_authorized_for?(user) }

    it { is_expected.to eq(false) }

    context 'with project-level authorization' do
      let!(:authorization) { create(:agent_user_access_project_authorization, agent: agent, project: deployment_project) }

      where(:user_role, :allowed) do
        :guest       | false
        :reporter    | false
        :developer   | true
        :maintainer  | true
        :owner       | true
      end

      with_them do
        before do
          deployment_project.add_member(user, user_role)
        end

        it { is_expected.to eq(allowed) }
      end
    end

    context 'with group-level authorization' do
      let!(:authorization) { create(:agent_user_access_group_authorization, agent: agent, group: organization) }

      where(:user_role, :allowed) do
        :guest       | false
        :reporter    | false
        :developer   | true
        :maintainer  | true
        :owner       | true
      end

      with_them do
        before do
          organization.add_member(user, user_role)
        end

        it { is_expected.to eq(allowed) }
      end
    end
  end

  describe '#user_access_config' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project) }
    let_it_be_with_refind(:agent) { create(:cluster_agent, project: project) }

    subject { agent.user_access_config }

    it { is_expected.to be_nil }

    context 'with user_access project authorizations' do
      before do
        create(:agent_user_access_project_authorization, agent: agent, project: project, config: config)
      end

      let(:config) { {} }

      it { is_expected.to eq(config) }

      context 'when access_as keyword exists' do
        let(:config) { { 'access_as' => { 'agent' => {} } } }

        it { is_expected.to eq(config) }
      end
    end

    context 'with user_access group authorizations' do
      before do
        create(:agent_user_access_group_authorization, agent: agent, group: group, config: config)
      end

      let(:config) { {} }

      it { is_expected.to eq(config) }

      context 'when access_as keyword exists' do
        let(:config) { { 'access_as' => { 'agent' => {} } } }

        it { is_expected.to eq(config) }
      end
    end
  end
end
