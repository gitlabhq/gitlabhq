# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UserPreferencePolicy, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }

  subject(:policy) { described_class.new(user, user_preference) }

  context 'when namespace is public' do
    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group, :public) }
      let_it_be(:user_preference) { create(:work_item_user_preference, namespace: namespace, user: user) }

      it { is_expected.to be_allowed(:read_namespace) }
    end

    context 'when namespace is a project' do
      let_it_be(:project) { create(:project, :public) }
      let_it_be(:namespace) { project.project_namespace }
      let_it_be(:user_preference) { create(:work_item_user_preference, namespace: namespace, user: user) }

      it { is_expected.to be_allowed(:read_namespace) }
    end
  end

  context 'when namespace is private' do
    context 'when namespace is a group' do
      let_it_be(:namespace) { create(:group, :private) }
      let_it_be(:user_preference) { create(:work_item_user_preference, namespace: namespace, user: user) }

      context 'when user is not member of the namespace' do
        it { is_expected.to be_disallowed(:read_namespace) }
      end

      context 'when user is member of the namespace' do
        before_all do
          namespace.add_guest(user)
        end

        it { is_expected.to be_allowed(:read_namespace) }
      end
    end

    context 'when namespace is a project' do
      let_it_be(:project) { create(:project, :private) }
      let_it_be(:namespace) { project.project_namespace }
      let_it_be(:user_preference) { create(:work_item_user_preference, namespace: namespace, user: user) }

      context 'when user is not member of the namespace' do
        it { is_expected.to be_disallowed(:read_namespace) }
      end

      context 'when user is member of the namespace' do
        before_all do
          project.add_guest(user)
        end

        it { is_expected.to be_allowed(:read_namespace) }
      end
    end
  end
end
