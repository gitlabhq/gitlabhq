require 'spec_helper.rb'

describe Issues::FetchReferencedMergeRequestsService do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:other_project) { create(:project) }

  let(:mr) { create(:merge_request, source_project: project, target_project: project, id: 2)}
  let(:other_mr) { create(:merge_request, source_project: other_project, target_project: other_project, id: 1)}

  let(:user) { create(:user) }
  let(:service) { described_class.new(project, user) }

  context 'with mentioned merge requests' do
    it 'returns a list of sorted merge requests' do
      allow(issue).to receive(:referenced_merge_requests).with(user).and_return([other_mr, mr])

      mrs, closed_by_mrs = service.execute(issue)

      expect(mrs).to match_array([mr, other_mr])
      expect(closed_by_mrs).to match_array([])
    end
  end

  context 'with closed-by merge requests' do
    it 'returns a list of sorted merge requests' do
      allow(issue).to receive(:closed_by_merge_requests).with(user).and_return([other_mr, mr])

      mrs, closed_by_mrs = service.execute(issue)

      expect(mrs).to match_array([])
      expect(closed_by_mrs).to match_array([mr, other_mr])
    end
  end
end
