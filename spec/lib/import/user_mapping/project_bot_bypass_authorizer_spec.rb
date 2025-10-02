# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UserMapping::ProjectBotBypassAuthorizer, feature_category: :importers do
  let_it_be(:group) { create(:group) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_bot) { create(:user, :project_bot, bot_namespace: project.namespace) }
  let_it_be(:subgroup_bot) { create(:user, :project_bot, bot_namespace: subgroup) }
  let_it_be(:different_namespace_project_bot) { create(:user, :project_bot, bot_namespace: create(:project).namespace) }

  before_all do
    group.add_owner(owner)
    group.add_maintainer(maintainer)
  end

  describe '#allowed?' do
    subject(:authorizer) { described_class.new(group, assignee_user, reassigned_by_user) }

    before do
      stub_feature_flags(user_mapping_service_account_and_bots: feature_flag_status)
    end

    context 'when all conditions met' do
      let(:assignee_user) { project_bot }
      let(:reassigned_by_user) { owner }
      let(:feature_flag_status) { true }

      it { is_expected.to be_allowed }
    end

    context 'when feature flag is disabled' do
      let(:assignee_user) { project_bot }
      let(:reassigned_by_user) { owner }
      let(:feature_flag_status) { false }

      it { is_expected.not_to be_allowed }
    end

    context 'when assignee_user is a subgroup bot' do
      let(:assignee_user) { subgroup_bot }
      let(:reassigned_by_user) { owner }
      let(:feature_flag_status) { true }

      it { is_expected.to be_allowed }
    end

    context 'when assignee_user is a bot from a different namespace' do
      let(:assignee_user) { different_namespace_project_bot }
      let(:reassigned_by_user) { owner }
      let(:feature_flag_status) { true }

      it { is_expected.not_to be_allowed }
    end

    context 'when assignee_user is not an bot' do
      let(:assignee_user) { user }
      let(:reassigned_by_user) { owner }
      let(:feature_flag_status) { true }

      it { is_expected.not_to be_allowed }
    end

    context 'when reassigned_by_user is not the group owner' do
      let(:assignee_user) { project_bot }
      let(:reassigned_by_user) { maintainer }
      let(:feature_flag_status) { true }

      it { is_expected.not_to be_allowed }
    end
  end
end
