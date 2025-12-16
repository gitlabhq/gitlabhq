# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::SavedViews::SavedViewPolicy, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:group) { create(:group) }

  subject(:policy) { described_class.new(user, saved_view) }

  describe 'is_author condition' do
    context 'when user is the author' do
      let(:saved_view) { create(:saved_view, created_by_id: user.id) }

      it { is_expected.to be_allowed(:read_saved_view) }
    end

    context 'when user is not the author and saved view is private' do
      let(:saved_view) { create(:saved_view, created_by_id: other_user.id, namespace: group, private: true) }

      before_all do
        group.add_developer(user)
      end

      it { is_expected.to be_disallowed(:read_saved_view) }
      it { is_expected.to be_disallowed(:update_saved_view) }
      it { is_expected.to be_disallowed(:delete_saved_view) }
    end

    context 'when user is nil' do
      subject(:policy) { described_class.new(nil, saved_view) }

      let(:saved_view) { create(:saved_view) }

      it { is_expected.to be_disallowed(:read_saved_view) }
      it { is_expected.to be_disallowed(:update_saved_view) }
      it { is_expected.to be_disallowed(:delete_saved_view) }
    end
  end

  describe 'has_planner_access condition' do
    context 'when namespace is a group' do
      let(:saved_view) { create(:saved_view, namespace: group, private: false) }

      context 'when user has planner access' do
        before do
          group.add_planner(user)
        end

        it { is_expected.to be_allowed(:read_saved_view) }
        it { is_expected.to be_allowed(:update_saved_view) }
        it { is_expected.to be_allowed(:delete_saved_view) }
      end

      context 'when user does not have planner access but can read namespace' do
        before_all do
          group.add_guest(user)
        end

        it 'allows reading public saved views' do
          expect(policy).to be_allowed(:read_saved_view)
        end

        it 'disallows updating and deleting' do
          expect(policy).to be_disallowed(:update_saved_view)
          expect(policy).to be_disallowed(:delete_saved_view)
        end
      end
    end

    context 'when namespace is a project namespace' do
      let_it_be(:project) { create(:project) }
      let_it_be(:saved_view) { create(:saved_view, namespace: project.project_namespace, private: false) }

      context 'when user has planner access' do
        before_all do
          project.add_planner(user)
        end

        it { is_expected.to be_allowed(:read_saved_view) }
        it { is_expected.to be_allowed(:update_saved_view) }
        it { is_expected.to be_allowed(:delete_saved_view) }
      end

      context 'when user does not have planner access but can read namespace' do
        before_all do
          project.add_guest(user)
        end

        it 'allows reading public saved views' do
          expect(policy).to be_allowed(:read_saved_view)
        end

        it 'disallows updating and deleting' do
          expect(policy).to be_disallowed(:update_saved_view)
          expect(policy).to be_disallowed(:delete_saved_view)
        end
      end
    end
  end

  describe 'read_saved_view' do
    context 'with public saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: false) }

      context 'when user can read namespace' do
        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_allowed(:read_saved_view) }
      end

      context 'when user cannot read namespace' do
        let_it_be(:private_group) { create(:group, :private) }
        let_it_be(:saved_view) { create(:saved_view, namespace: private_group, private: false) }

        it { is_expected.to be_disallowed(:read_saved_view) }
      end
    end

    context 'with private saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: other_user.id) }

      context 'when user is the author' do
        let(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: user.id) }

        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_allowed(:read_saved_view) }
      end

      context 'when user is not the author' do
        before_all do
          group.add_planner(user)
        end

        it { is_expected.to be_disallowed(:read_saved_view) }
      end
    end
  end

  describe 'update_saved_view' do
    context 'with shared saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: false, created_by_id: other_user.id) }

      context 'when user has planner access' do
        before_all do
          group.add_planner(user)
        end

        it { is_expected.to be_allowed(:update_saved_view) }
      end

      context 'when user does not have planner access' do
        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_disallowed(:update_saved_view) }
      end
    end

    context 'with private saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: other_user.id) }

      context 'when user is the author' do
        let(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: user.id) }

        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_allowed(:update_saved_view) }
      end

      context 'when user is not the author but has planner access' do
        before_all do
          group.add_planner(user)
        end

        it { is_expected.to be_disallowed(:update_saved_view) }
      end
    end
  end

  describe 'delete_saved_view' do
    context 'with shared saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: false, created_by_id: other_user.id) }

      context 'when user has planner access' do
        before_all do
          group.add_planner(user)
        end

        it { is_expected.to be_allowed(:delete_saved_view) }
      end

      context 'when user does not have planner access' do
        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_disallowed(:delete_saved_view) }
      end
    end

    context 'with private saved view' do
      let_it_be(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: other_user.id) }

      context 'when user is the author' do
        let(:saved_view) { create(:saved_view, namespace: group, private: true, created_by_id: user.id) }

        before_all do
          group.add_guest(user)
        end

        it { is_expected.to be_allowed(:delete_saved_view) }
      end

      context 'when user is not the author but has planner access' do
        before_all do
          group.add_planner(user)
        end

        it { is_expected.to be_disallowed(:delete_saved_view) }
      end
    end
  end
end
