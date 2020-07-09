# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::CreateIncidentLabelService do
  let_it_be(:project) { create(:project, :private) }
  let_it_be(:user) { User.alert_bot }
  let(:service) { described_class.new(project, user) }

  subject(:execute) { service.execute }

  describe 'execute' do
    let(:title) { described_class::LABEL_PROPERTIES[:title] }
    let(:color) { described_class::LABEL_PROPERTIES[:color] }
    let(:description) { described_class::LABEL_PROPERTIES[:description] }

    shared_examples 'existing label' do
      it 'returns the existing label' do
        expect { execute }.not_to change(Label, :count)

        expect(execute).to be_success
        expect(execute.payload).to eq(label: label)
      end
    end

    shared_examples 'new label' do
      it 'creates a new label' do
        expect { execute }.to change(Label, :count).by(1)

        label = project.reload.labels.last
        expect(execute).to be_success
        expect(execute.payload).to eq(label: label)
        expect(label.title).to eq(title)
        expect(label.color).to eq(color)
        expect(label.description).to eq(description)
      end
    end

    context 'with predefined project label' do
      it_behaves_like 'existing label' do
        let!(:label) { create(:label, project: project, title: title) }
      end
    end

    context 'with predefined group label' do
      let(:project) { create(:project, group: group) }
      let(:group) { create(:group) }

      it_behaves_like 'existing label' do
        let!(:label) { create(:group_label, group: group, title: title) }
      end
    end

    context 'without label' do
      it_behaves_like 'new label'
    end
  end
end
