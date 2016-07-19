require 'spec_helper'

describe Gitlab::ImportExport, services: true do
  describe 'export filename' do
    let(:project) { create(:project, :public, path: 'project-path') }

    it 'contains the project path' do
      expect(described_class.export_filename(project: project)).to include(project.path)
    end

    it 'contains the namespace path' do
      expect(described_class.export_filename(project: project)).to include(project.namespace.path)
    end

    it 'does not go over a certain length' do
      project.path = 'a' * 100

      expect(described_class.export_filename(project: project).length).to be < 70
    end
  end
end
