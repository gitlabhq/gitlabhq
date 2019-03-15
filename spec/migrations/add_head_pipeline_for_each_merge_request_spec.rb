require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20170508170547_add_head_pipeline_for_each_merge_request.rb')

describe AddHeadPipelineForEachMergeRequest, :migration do
  let(:migration) { described_class.new }

  let!(:project) { table(:projects).create! }
  let!(:other_project) { table(:projects).create! }

  let!(:pipeline_1) { table(:ci_pipelines).create!(project_id: project.id, ref: "branch_1") }
  let!(:pipeline_2) { table(:ci_pipelines).create!(project_id: other_project.id, ref: "branch_1") }
  let!(:pipeline_3) { table(:ci_pipelines).create!(project_id: other_project.id, ref: "branch_1") }
  let!(:pipeline_4) { table(:ci_pipelines).create!(project_id: project.id, ref: "branch_2") }

  let!(:mr_1) { table(:merge_requests).create!(source_project_id: project.id, target_project_id: project.id, source_branch: "branch_1", target_branch: "target_1") }
  let!(:mr_2) { table(:merge_requests).create!(source_project_id: other_project.id, target_project_id: project.id, source_branch: "branch_1", target_branch: "target_2") }
  let!(:mr_3) { table(:merge_requests).create!(source_project_id: project.id, target_project_id: project.id, source_branch: "branch_2", target_branch: "master") }
  let!(:mr_4) { table(:merge_requests).create!(source_project_id: project.id, target_project_id: project.id, source_branch: "branch_3", target_branch: "master") }

  context "#up" do
    context "when source_project and source_branch of pipeline are the same of merge request" do
      it "sets head_pipeline_id of given merge requests" do
        migration.up

        expect(mr_1.reload.head_pipeline_id).to eq(pipeline_1.id)
        expect(mr_2.reload.head_pipeline_id).to eq(pipeline_3.id)
        expect(mr_3.reload.head_pipeline_id).to eq(pipeline_4.id)
        expect(mr_4.reload.head_pipeline_id).to be_nil
      end
    end
  end
end
