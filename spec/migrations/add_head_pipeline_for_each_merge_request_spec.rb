require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170505170547_add_head_pipeline_for_each_merge_request.rb')

describe AddHeadPipelineForEachMergeRequest do
  let(:migration) { described_class.new }

  let!(:project) { create(:empty_project) }
  let!(:forked_project_link) { create(:forked_project_link, forked_from_project: project) }
  let!(:other_project) { forked_project_link.forked_to_project }

  let!(:pipeline_1) { create(:ci_pipeline, project: project, ref: "branch_1") }
  let!(:pipeline_2) { create(:ci_pipeline, project: other_project, ref: "branch_1") }
  let!(:pipeline_3) { create(:ci_pipeline, project: other_project, ref: "branch_1") }
  let!(:pipeline_4) { create(:ci_pipeline, project: project, ref: "branch_2") }

  let!(:mr_1) { create(:merge_request, source_project: project, target_project: project, source_branch: "branch_1", target_branch: "target_1") }
  let!(:mr_2) { create(:merge_request, source_project: other_project, target_project: project, source_branch: "branch_1", target_branch: "target_2") }
  let!(:mr_3) { create(:merge_request, source_project: project, target_project: project, source_branch: "branch_2", target_branch: "master") }

  context "#up" do
    it "correctly sets head_pipeline_id for each merge request" do
      migration.up

      expect(mr_1.reload.head_pipeline_id).to eq(pipeline_1.id)
      expect(mr_2.reload.head_pipeline_id).to eq(pipeline_3.id)
      expect(mr_3.reload.head_pipeline_id).to eq(pipeline_4.id)
    end
  end
end
