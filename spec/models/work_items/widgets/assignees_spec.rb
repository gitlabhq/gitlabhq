# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Assignees do
  let_it_be(:work_item) { create(:work_item, assignees: [create(:user)]) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:assignees) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:assignee_ids) }
  end

  describe '.can_invite_members?' do
    let(:user) { build_stubbed(:user) }

    subject(:execute) { described_class.can_invite_members?(user, resource_parent) }

    context 'when resource_parent is a project' do
      let(:resource_parent) { build_stubbed(:project) }

      it 'checks the ability with the correct permission' do
        expect(Ability).to receive(:allowed?).with(user, :admin_project_member, resource_parent)

        execute
      end

      context 'when user is nil' do
        let(:user) { nil }

        it { is_expected.to eq(false) }
      end
    end

    context 'when resource_parent is a group' do
      let(:resource_parent) { build_stubbed(:group) }

      it 'checks the ability with the correct permission' do
        expect(Ability).to receive(:allowed?).with(user, :admin_group_member, resource_parent)

        execute
      end

      context 'when user is nil' do
        let(:user) { nil }

        it { is_expected.to eq(false) }
      end
    end
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:assignees) }
  end

  describe '#assignees' do
    subject { described_class.new(work_item).assignees }

    it { is_expected.to eq(work_item.assignees) }
  end

  describe '#allows_multiple_assignees?' do
    subject { described_class.new(work_item).allows_multiple_assignees? }

    it { is_expected.to eq(work_item.allows_multiple_assignees?) }
  end
end
