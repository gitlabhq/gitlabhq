# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BoardPolicy, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:project) { create(:project, :private) }
  let_it_be_with_reload(:group) { create(:group, :private) }
  let_it_be(:group_board) { create(:board, group: group) }
  let_it_be(:project_board) { create(:board, project: project) }

  let(:board_permissions) do
    [
      :read_parent,
      :read_milestone,
      :read_issue
    ]
  end

  context 'group board' do
    subject { described_class.new(user, group_board) }

    context 'user has access' do
      before_all do
        group.add_developer(user)
      end

      it do
        expect_allowed(*board_permissions)
      end
    end

    context 'user does not have access' do
      it do
        expect_disallowed(*board_permissions)
      end
    end
  end

  context 'project board' do
    subject { described_class.new(user, project_board) }

    context 'user has access' do
      before_all do
        project.add_developer(user)
      end

      it do
        expect_allowed(*board_permissions)
      end
    end

    context 'user does not have access' do
      it do
        expect_disallowed(*board_permissions)
      end
    end
  end

  context 'create_non_backlog_issues' do
    shared_examples 'with admin' do
      let!(:current_user) { create(:user, :admin) }

      context 'when admin mode enabled', :enable_admin_mode do
        it 'allows to add non backlog issues from issue board' do
          expect_allowed(:create_non_backlog_issues)
        end
      end

      context 'when admin mode disabled' do
        it 'does not allow to add non backlog issues from issue board' do
          expect_disallowed(:create_non_backlog_issues)
        end
      end
    end

    context 'for project boards' do
      let!(:current_user) { create(:user) }

      subject { described_class.new(current_user, project_board) }

      it_behaves_like 'with admin'

      context 'when user can admin project issues' do
        it 'allows to add non backlog issues from issue board' do
          project.add_planner(current_user)

          expect_allowed(:create_non_backlog_issues)
        end
      end

      context 'when user cannot admin project issues' do
        it 'does not allow to add non backlog issues from issue board' do
          project.add_guest(current_user)

          expect_disallowed(:create_non_backlog_issues)
        end
      end
    end

    context 'for group boards' do
      let_it_be(:guest) { create(:user) }
      let_it_be(:planner) { create(:user) }
      let_it_be(:reporter) { create(:user) }
      let_it_be(:group_board) { create(:board, group: group) }
      let_it_be(:project_2) do
        create(:project, namespace: group, guests: guest, planners: planner, reporters: reporter)
      end

      let(:current_user) { nil }

      subject { described_class.new(current_user, group_board) }

      it_behaves_like 'with admin'

      context 'with planner or reporter role in a child project' do
        where(role: %w[planner reporter])

        with_them do
          let(:current_user) { public_send(role) }

          it { expect_allowed(:create_non_backlog_issues) }
        end
      end

      context 'when user is not at least a planner from any child projects' do
        let(:current_user) { guest }

        it { expect_disallowed(:create_non_backlog_issues) }
      end
    end
  end
end
