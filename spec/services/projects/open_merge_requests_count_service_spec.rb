require 'spec_helper'

describe Projects::OpenMergeRequestsCountService do
  describe '#count' do
    it 'returns the number of open merge requests' do
      project = create(:project)
      create(:merge_request,
             :opened,
             source_project: project,
             target_project: project)

      expect(described_class.new(project).count).to eq(1)
    end
  end
end
