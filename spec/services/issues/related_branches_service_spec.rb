# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RelatedBranchesService do
  let_it_be(:developer) { create(:user) }
  let_it_be(:issue) { create(:issue) }

  let(:user) { developer }

  subject { described_class.new(project: issue.project, current_user: user) }

  before do
    issue.project.add_developer(developer)
  end

  describe '#execute' do
    let(:sha) { 'abcdef' }
    let(:repo) { issue.project.repository }
    let(:project) { issue.project }
    let(:branch_info) { subject.execute(issue) }

    def make_branch
      double('Branch', dereferenced_target: double('Target', sha: sha))
    end

    before do
      allow(repo).to receive(:branch_names).and_return(branch_names)
    end

    context 'no branches are available' do
      let(:branch_names) { [] }

      it 'returns an empty array' do
        expect(branch_info).to be_empty
      end
    end

    context 'branches are available' do
      let(:missing_branch) { "#{issue.to_branch_name}-missing" }
      let(:unreadable_branch_name) { "#{issue.to_branch_name}-unreadable" }
      let(:pipeline) { build(:ci_pipeline, :success, project: project) }
      let(:unreadable_pipeline) { build(:ci_pipeline, :running) }

      let(:branch_names) do
        [
          generate(:branch),
          "#{issue.iid}doesnt-match",
          issue.to_branch_name,
          missing_branch,
          unreadable_branch_name
        ]
      end

      before do
        {
          issue.to_branch_name => pipeline,
          unreadable_branch_name => unreadable_pipeline
        }.each do |name, pipeline|
          allow(repo).to receive(:find_branch).with(name).and_return(make_branch)
          allow(project).to receive(:latest_pipeline).with(name, sha).and_return(pipeline)
        end

        allow(repo).to receive(:find_branch).with(missing_branch).and_return(nil)
      end

      it 'selects relevant branches, along with pipeline status where available' do
        expect(branch_info).to contain_exactly(
          { name: issue.to_branch_name, pipeline_status: an_instance_of(Gitlab::Ci::Status::Success) },
          { name: missing_branch, pipeline_status: be_nil },
          { name: unreadable_branch_name, pipeline_status: be_nil }
        )
      end

      context 'the user has access to otherwise unreadable pipelines' do
        let(:user) { create(:admin) }

        context 'when admin mode is enabled', :enable_admin_mode do
          it 'returns info a developer could not see' do
            expect(branch_info.pluck(:pipeline_status)).to include(an_instance_of(Gitlab::Ci::Status::Running))
          end
        end

        context 'when admin mode is disabled' do
          it 'does not return info a developer could not see' do
            expect(branch_info.pluck(:pipeline_status)).not_to include(an_instance_of(Gitlab::Ci::Status::Running))
          end
        end
      end

      it 'excludes branches referenced in merge requests' do
        merge_request = create(:merge_request, { description: "Closes #{issue.to_reference}",
                                                 source_project: issue.project,
                                                 source_branch: issue.to_branch_name })
        merge_request.create_cross_references!(user)

        referenced_merge_requests = Issues::ReferencedMergeRequestsService
                                      .new(project: issue.project, current_user: user)
                                      .referenced_merge_requests(issue)

        expect(referenced_merge_requests).not_to be_empty
        expect(branch_info.pluck(:name)).not_to include(merge_request.source_branch)
      end
    end

    context 'one of the branches is stable' do
      let(:branch_names) { ["#{issue.iid}-0-stable"] }

      it 'is excluded' do
        expect(branch_info).to be_empty
      end
    end
  end
end
