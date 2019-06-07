# frozen_string_literal: true

require 'spec_helper'

describe Issues::RelatedBranchesService do
  let(:user) { create(:admin) }
  let(:issue) { create(:issue) }

  subject { described_class.new(issue.project, user) }

  describe '#execute' do
    before do
      allow(issue.project.repository).to receive(:branch_names).and_return(["mpempe", "#{issue.iid}mepmep", issue.to_branch_name, "#{issue.iid}-branch"])
    end

    it "selects the right branches when there are no referenced merge requests" do
      expect(subject.execute(issue)).to eq([issue.to_branch_name, "#{issue.iid}-branch"])
    end

    it "selects the right branches when there is a referenced merge request" do
      merge_request = create(:merge_request, { description: "Closes ##{issue.iid}",
                                               source_project: issue.project,
                                               source_branch: "#{issue.iid}-branch" })
      merge_request.create_cross_references!(user)

      referenced_merge_requests = Issues::ReferencedMergeRequestsService
                                    .new(issue.project, user)
                                    .referenced_merge_requests(issue)

      expect(referenced_merge_requests).not_to be_empty
      expect(subject.execute(issue)).to eq([issue.to_branch_name])
    end

    it 'excludes stable branches from the related branches' do
      allow(issue.project.repository).to receive(:branch_names)
        .and_return(["#{issue.iid}-0-stable"])

      expect(subject.execute(issue)).to eq []
    end
  end
end
