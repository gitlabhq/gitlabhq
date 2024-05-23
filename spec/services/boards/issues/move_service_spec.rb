# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Issues::MoveService, feature_category: :portfolio_management do
  describe '#execute' do
    context 'when parent is a project' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:board1) { create(:board, project: project) }
      let(:board2) { create(:board, project: project) }

      let(:bug) { create(:label, project: project, name: 'Bug') }
      let(:development) { create(:label, project: project, name: 'Development') }
      let(:testing) { create(:label, project: project, name: 'Testing') }
      let(:regression) { create(:label, project: project, name: 'Regression') }

      let!(:list1)   { create(:list, board: board1, label: development, position: 0) }
      let!(:list2)   { create(:list, board: board1, label: testing, position: 1) }
      let!(:closed)  { create(:closed_list, board: board1) }

      let(:parent) { project }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues move service'
    end

    context 'when parent is a group' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:project) { create(:project, namespace: group) }
      let(:board1) { create(:board, group: group) }
      let(:board2) { create(:board, group: group) }

      let(:bug) { create(:group_label, group: group, name: 'Bug') }
      let(:development) { create(:group_label, group: group, name: 'Development') }
      let(:testing) { create(:group_label, group: group, name: 'Testing') }
      let(:regression) { create(:group_label, group: group, name: 'Regression') }

      let!(:list1)   { create(:list, board: board1, label: development, position: 0) }
      let!(:list2)   { create(:list, board: board1, label: testing, position: 1) }
      let!(:closed)  { create(:closed_list, board: board1) }

      let(:parent) { group }

      before do
        parent.add_developer(user)
      end

      it_behaves_like 'issues move service', true
    end

    describe '#execute_multiple' do
      let_it_be(:group)  { create(:group) }
      let_it_be(:user)   { create(:user) }
      let_it_be(:project) { create(:project, namespace: group) }
      let_it_be(:board1) { create(:board, group: group) }
      let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
      let_it_be(:testing) { create(:group_label, group: group, name: 'Testing') }
      let_it_be(:list1) { create(:list, board: board1, label: development, position: 0) }
      let_it_be(:list2) { create(:list, board: board1, label: testing, position: 1) }

      let(:params) { { board_id: board1.id, from_list_id: list1.id, to_list_id: list2.id } }

      before do
        project.add_developer(user)
      end

      it 'returns the expected result if list of issues is empty' do
        expect(described_class.new(group, user, params).execute_multiple([])).to eq({ count: 0, success: false, issues: [] })
      end

      context 'moving multiple issues' do
        let(:issue1) { create(:labeled_issue, project: project, labels: [development]) }
        let(:issue2) { create(:labeled_issue, project: project, labels: [development]) }

        it 'moves multiple issues from one list to another' do
          expect(described_class.new(group, user, params).execute_multiple([issue1, issue2])).to be_truthy

          expect(issue1.labels).to eq([testing])
          expect(issue2.labels).to eq([testing])
        end
      end

      context 'moving a single issue' do
        let(:issue1) { create(:labeled_issue, project: project, labels: [development]) }

        it 'moves one issue' do
          expect(described_class.new(group, user, params).execute_multiple([issue1])).to be_truthy

          expect(issue1.labels).to eq([testing])
        end
      end

      context 'moving issues visually after an existing issue' do
        let(:existing_issue) { create(:labeled_issue, project: project, labels: [testing], relative_position: 10) }
        let(:issue1) { create(:labeled_issue, project: project, labels: [development]) }
        let(:issue2) { create(:labeled_issue, project: project, labels: [development]) }

        let(:move_params) do
          params.dup.tap do |hash|
            hash[:move_before_id] = existing_issue.id
          end
        end

        it 'moves one issue' do
          expect(described_class.new(group, user, move_params).execute_multiple([issue1, issue2])).to be_truthy

          expect(issue1.labels).to eq([testing])
          expect(issue2.labels).to eq([testing])

          expect(issue1.relative_position > existing_issue.relative_position).to eq(true)
          expect(issue2.relative_position > issue1.relative_position).to eq(true)
        end
      end

      context 'moving issues visually before an existing issue' do
        let(:existing_issue) { create(:labeled_issue, project: project, labels: [testing], relative_position: 10) }
        let(:issue1) { create(:labeled_issue, project: project, labels: [development]) }
        let(:issue2) { create(:labeled_issue, project: project, labels: [development]) }

        let(:move_params) do
          params.dup.tap do |hash|
            hash[:move_after_id] = existing_issue.id
          end
        end

        it 'moves one issue' do
          expect(described_class.new(group, user, move_params).execute_multiple([issue1, issue2])).to be_truthy

          expect(issue1.labels).to eq([testing])
          expect(issue2.labels).to eq([testing])

          expect(issue2.relative_position < existing_issue.relative_position).to eq(true)
          expect(issue1.relative_position < issue2.relative_position).to eq(true)
        end
      end
    end
  end
end
