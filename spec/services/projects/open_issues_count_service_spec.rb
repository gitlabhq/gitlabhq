require 'spec_helper'

describe Projects::OpenIssuesCountService do
  describe '#count' do
    it 'returns the number of open issues' do
      project = create(:project)
      create(:issue, :opened, project: project)

      expect(described_class.new(project).count).to eq(1)
    end

    it 'does not include confidential issues in the issue count' do
      project = create(:project)

      create(:issue, :opened, project: project)
      create(:issue, :opened, confidential: true, project: project)

      expect(described_class.new(project).count).to eq(1)
    end
  end
end
