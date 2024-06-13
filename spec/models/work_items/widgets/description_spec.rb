# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Description do
  let_it_be(:user) { create(:user) }
  let_it_be(:description) do
    <<~DESC
      - [ ] One
      - [ ] Two
      - [x] Three
    DESC
  end

  let_it_be(:work_item, refind: true) do
    create(:work_item, description: description, last_edited_at: 10.days.ago, last_edited_by: user)
  end

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:description) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:description) }
  end

  describe '#description' do
    subject { described_class.new(work_item).description }

    it { is_expected.to eq(work_item.description) }
  end

  describe '#edited?' do
    subject { described_class.new(work_item).edited? }

    it { is_expected.to be_truthy }
  end

  describe '#last_edited_at' do
    subject { described_class.new(work_item).last_edited_at }

    it { is_expected.to eq(work_item.last_edited_at) }
  end

  describe '#last_edited_by' do
    subject { described_class.new(work_item).last_edited_by }

    context 'when the work item is edited' do
      context 'when last edited user still exists in the DB' do
        it { is_expected.to eq(user) }
      end

      context 'when last edited user no longer exists' do
        before do
          work_item.update!(last_edited_by: nil)
        end

        it { is_expected.to eq(Users::Internal.ghost) }
      end
    end

    context 'when the work item is not edited yet' do
      before do
        work_item.update!(last_edited_at: nil)
      end

      it { is_expected.to be_nil }
    end
  end

  describe '#task_completion_status' do
    subject { described_class.new(work_item).task_completion_status }

    expected_status = { completed_count: 1, count: 3 }

    it { is_expected.to eq(expected_status) }
  end
end
