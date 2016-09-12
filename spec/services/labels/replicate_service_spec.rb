require 'spec_helper'

describe Labels::ReplicateService, services: true do
  describe '#execute' do
    let(:group)   { create(:group) }
    let(:project) { create(:empty_project, group: group) }

    subject(:service) { described_class.new(project, double) }

    it 'replicates global labels' do
      create_list(:label, 2, template: true)

      expect { service.execute }.to change(project.labels, :count).by(2)
    end

    it 'replicates group labels' do
      create_list(:label, 2, subject: group)

      expect { service.execute }.to change(project.labels, :count).by(2)
    end
  end
end
