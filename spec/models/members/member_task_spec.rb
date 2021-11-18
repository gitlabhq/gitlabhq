# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MemberTask do
  describe 'Associations' do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validations' do
    it { is_expected.to validate_presence_of(:member) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_inclusion_of(:tasks).in_array(MemberTask::TASKS.values) }

    describe 'unique tasks validation' do
      subject do
        build(:member_task, tasks: [0, 0])
      end

      it 'expects the task values to be unique' do
        expect(subject).to be_invalid
        expect(subject.errors[:tasks]).to include('are not unique')
      end
    end

    describe 'project validations' do
      let_it_be(:project) { create(:project) }

      subject do
        build(:member_task, member: member, project: project, tasks_to_be_done: [:ci, :code])
      end

      context 'when the member source is a group' do
        let_it_be(:member) { create(:group_member) }

        it "expects the project to be part of the member's group projects" do
          expect(subject).to be_invalid
          expect(subject.errors[:project]).to include('is not in the member group')
        end

        context "when the project is part of the member's group projects" do
          let_it_be(:project) { create(:project, namespace: member.source) }

          it { is_expected.to be_valid }
        end
      end

      context 'when the member source is a project' do
        let_it_be(:member) { create(:project_member) }

        it "expects the project to be the member's project" do
          expect(subject).to be_invalid
          expect(subject.errors[:project]).to include('is not the member project')
        end

        context "when the project is the member's project" do
          let_it_be(:project) { member.source }

          it { is_expected.to be_valid }
        end
      end
    end
  end

  describe '.for_members' do
    it 'returns the member_tasks for multiple members' do
      member1 = create(:group_member)
      member_task1 = create(:member_task, member: member1)
      create(:member_task)
      expect(described_class.for_members([member1])).to match_array([member_task1])
    end
  end

  describe '#tasks_to_be_done' do
    subject { member_task.tasks_to_be_done }

    let_it_be(:member_task) { build(:member_task) }

    before do
      member_task[:tasks] = [0, 1]
    end

    it 'returns an array of symbols for the corresponding integers' do
      expect(subject).to match_array([:ci, :code])
    end
  end

  describe '#tasks_to_be_done=' do
    let_it_be(:member_task) { build(:member_task) }

    context 'when passing valid values' do
      subject { member_task[:tasks] }

      before do
        member_task.tasks_to_be_done = tasks
      end

      context 'when passing tasks as strings' do
        let_it_be(:tasks) { %w(ci code) }

        it 'sets an array of integers for the corresponding tasks' do
          expect(subject).to match_array([0, 1])
        end
      end

      context 'when passing a single task' do
        let_it_be(:tasks) { :ci }

        it 'sets an array of integers for the corresponding tasks' do
          expect(subject).to match_array([1])
        end
      end

      context 'when passing a task twice' do
        let_it_be(:tasks) { %w(ci ci) }

        it 'is set only once' do
          expect(subject).to match_array([1])
        end
      end
    end
  end
end
