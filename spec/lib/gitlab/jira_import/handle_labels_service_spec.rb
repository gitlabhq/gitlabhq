# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::JiraImport::HandleLabelsService do
  describe '#execute' do
    let_it_be(:group)   { create(:group) }
    let_it_be(:project) { create(:project, group: group) }

    let_it_be(:project_label)       { create(:label, project: project, title: 'bug') }
    let_it_be(:other_project_label) { create(:label, title: 'feature') }
    let_it_be(:group_label)         { create(:group_label, group: group, title: 'dev') }

    let(:jira_labels)               { %w[bug feature dev group::new] }

    subject { described_class.new(project, jira_labels).execute }

    context 'when some provided jira labels are missing' do
      def created_labels
        project.labels.reorder(id: :desc).first(2)
      end

      it 'creates the missing labels on the project level' do
        expect { subject }.to change { Label.count }.from(3).to(5)

        expect(created_labels.map(&:title)).to match_array(%w[feature group::new])
      end

      it 'returns the id of all labels matching the title' do
        expect(subject).to match_array([project_label.id, group_label.id] + created_labels.map(&:id))
      end
    end

    context 'when no provided jira labels are missing' do
      let(:jira_labels) { %w[bug dev] }

      it 'does not create any new labels' do
        expect { subject }.not_to change { Label.count }.from(3)
      end

      it 'returns the id of all labels matching the title' do
        expect(subject).to match_array([project_label.id, group_label.id])
      end
    end

    context 'when no labels are provided' do
      let(:jira_labels) { [] }

      it 'does not create any new labels' do
        expect { subject }.not_to change { Label.count }.from(3)
      end
    end
  end
end
