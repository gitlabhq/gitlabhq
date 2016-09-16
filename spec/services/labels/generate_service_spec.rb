require 'spec_helper'

describe Labels::GenerateService, services: true do
  describe '#execute' do
    let(:project) { create(:empty_project) }

    subject(:service) { described_class.new(project, double, label_type: :project_label) }

    context 'when project labels is empty' do
      it 'creates the default labels' do
        expect { service.execute }.to change(project.labels, :count).by(8)
      end
    end

    context 'when project labels contains some of default labels' do
      it 'creates the missing labels' do
        create(:label, subject: project, name: 'bug')
        create(:label, subject: project, name: 'critical')

        expect { service.execute }.to change(project.labels, :count).by(6)
      end
    end
  end
end
