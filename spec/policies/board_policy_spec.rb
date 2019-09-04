# frozen_string_literal: true

require 'spec_helper'

describe BoardPolicy do
  let(:user) { create(:user) }
  let(:project) { create(:project, :private) }
  let(:group) { create(:group, :private) }
  let(:group_board) { create(:board, group: group) }
  let(:project_board) { create(:board, project: project) }

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
      before do
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
      before do
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
    context 'for project boards' do
      let!(:current_user) { create(:user) }

      subject { described_class.new(current_user, project_board) }

      context 'when user can admin project issues' do
        it 'allows to add non backlog issues from issue board' do
          project.add_reporter(current_user)

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
      let!(:current_user) { create(:user) }
      let!(:project_1) { create(:project, namespace: group) }
      let!(:project_2) { create(:project, namespace: group) }
      let!(:group_board) { create(:board, group: group) }

      subject { described_class.new(current_user, group_board) }

      before do
        project_1.add_guest(current_user)
      end

      context 'when user is at least reporter in one of the child projects' do
        it 'allows to add non backlog issues from issue board' do
          project_2.add_reporter(current_user)

          expect_allowed(:create_non_backlog_issues)
        end
      end

      context 'when user is not a reporter from any child projects' do
        it 'does not allow to add non backlog issues from issue board' do
          project_2.add_guest(current_user)

          expect_disallowed(:create_non_backlog_issues)
        end
      end
    end
  end
end
