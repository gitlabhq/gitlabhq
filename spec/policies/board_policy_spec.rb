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
end
