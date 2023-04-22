# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::SlackOptions::LabelSearchHandler, feature_category: :integrations do
  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :private, namespace: group) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:chat_name) { create(:chat_name, user: current_user) }
    let_it_be(:project_label1) { create(:label, project: project, title: 'Label 1') }
    let_it_be(:project_label2) { create(:label, project: project, title: 'Label 2') }
    let_it_be(:group_label1) { create(:group_label, group: group, title: 'LabelG 1') }
    let_it_be(:group_label2) { create(:group_label, group: group, title: 'glb 2') }
    let_it_be(:view_id) { 'VXHD54DR' }

    let(:search_value) { 'Lab' }

    subject(:execute) { described_class.new(chat_name, search_value, view_id).execute }

    context 'when user has permission to read project and group labels' do
      before do
        allow(Rails.cache).to receive(:read).and_return(project.id)
        project.add_developer(current_user)
      end

      it 'returns the labels matching the search term' do
        labels = execute.payload[:options]
        label_names = labels.map { |label| label.dig(:text, :text) }

        expect(label_names).to contain_exactly(
          project_label1.name,
          project_label2.name,
          group_label1.name
        )
      end
    end

    context 'when user does not have permissions to read project/group labels' do
      it 'returns empty array' do
        expect(LabelsFinder).not_to receive(:execute)

        expect(execute.payload).to be_empty
      end
    end
  end
end
