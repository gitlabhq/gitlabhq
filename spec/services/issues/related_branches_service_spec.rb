# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issues::RelatedBranchesService, feature_category: :team_planning do
  let_it_be(:project) { create(:project, :repository, :public, public_builds: false) }
  let_it_be(:developer) { create(:user, developer_of: project) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:user) { developer }

  subject { described_class.new(container: project, current_user: user) }

  describe '#execute' do
    let(:branch_info) { subject.execute(issue) }

    context 'branches are available' do
      let_it_be(:pipeline) { create(:ci_pipeline, :success, project: project, ref: issue.to_branch_name) }
      let_it_be(:branch_compare_path) do
        Gitlab::Routing.url_helpers.project_compare_path(
          project,
          from: project.default_branch,
          to: issue.to_branch_name
        )
      end

      before_all do
        project.repository.create_branch(issue.to_branch_name, pipeline.sha)
        project.repository.create_branch("#{issue.iid}doesnt-match", project.repository.root_ref)
        project.repository.create_branch("#{issue.iid}-0-stable", project.repository.root_ref)

        project.repository.add_tag(developer, issue.to_branch_name, pipeline.sha)
      end

      context 'when user has access to pipelines' do
        it 'selects relevant branches, along with pipeline status' do
          expect(branch_info).to contain_exactly(
            {
              name: issue.to_branch_name,
              pipeline_status: an_instance_of(Gitlab::Ci::Status::Success),
              compare_path: branch_compare_path
            }
          )
        end
      end

      context 'when user does not have access to pipelines' do
        let(:user) { create(:user) }

        it 'returns branches without pipeline status' do
          expect(branch_info).to contain_exactly(
            { name: issue.to_branch_name, pipeline_status: nil, compare_path: branch_compare_path }
          )
        end
      end

      it 'excludes branches referenced in merge requests' do
        merge_request = create(:merge_request, { description: "Closes #{issue.to_reference}",
                                                 source_project: issue.project,
                                                 source_branch: issue.to_branch_name })
        merge_request.create_cross_references!(user)

        referenced_merge_requests = Issues::ReferencedMergeRequestsService
                                      .new(container: issue.project, current_user: user)
                                      .referenced_merge_requests(issue)

        expect(referenced_merge_requests).not_to be_empty
        expect(branch_info.pluck(:name)).not_to include(merge_request.source_branch)
      end
    end

    context 'no branches are available' do
      let(:project) { create(:project, :empty_repo) }

      it 'returns an empty array' do
        expect(branch_info).to be_empty
      end
    end
  end
end
