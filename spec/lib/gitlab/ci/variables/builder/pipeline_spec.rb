# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Variables::Builder::Pipeline, feature_category: :ci_variables do
  let_it_be(:project) { create_default(:project, :repository, create_tag: 'test').freeze }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { build(:ci_empty_pipeline, :created, project: project) }

  describe '#predefined_variables' do
    subject { described_class.new(pipeline).predefined_variables }

    it 'includes all predefined variables in a valid order' do
      keys = subject.pluck(:key)

      expect(keys).to contain_exactly(*%w[
        CI_PIPELINE_IID
        CI_PIPELINE_SOURCE
        CI_PIPELINE_CREATED_AT
        CI_PIPELINE_NAME
        CI_COMMIT_SHA
        CI_COMMIT_SHORT_SHA
        CI_COMMIT_BEFORE_SHA
        CI_COMMIT_REF_NAME
        CI_COMMIT_REF_SLUG
        CI_COMMIT_BRANCH
        CI_COMMIT_MESSAGE
        CI_COMMIT_TITLE
        CI_COMMIT_DESCRIPTION
        CI_COMMIT_REF_PROTECTED
        CI_COMMIT_TIMESTAMP
        CI_COMMIT_AUTHOR
      ])
    end

    context 'when the pipeline is running for a tag' do
      let(:pipeline) { build(:ci_empty_pipeline, :created, project: project, ref: 'test', tag: true) }

      it 'includes all predefined variables in a valid order' do
        keys = subject.pluck(:key)

        expect(keys).to contain_exactly(*%w[
          CI_PIPELINE_IID
          CI_PIPELINE_SOURCE
          CI_PIPELINE_CREATED_AT
          CI_PIPELINE_NAME
          CI_COMMIT_SHA
          CI_COMMIT_SHORT_SHA
          CI_COMMIT_BEFORE_SHA
          CI_COMMIT_REF_NAME
          CI_COMMIT_REF_SLUG
          CI_COMMIT_MESSAGE
          CI_COMMIT_TITLE
          CI_COMMIT_DESCRIPTION
          CI_COMMIT_REF_PROTECTED
          CI_COMMIT_TIMESTAMP
          CI_COMMIT_AUTHOR
          CI_COMMIT_TAG
          CI_COMMIT_TAG_MESSAGE
        ])
      end
    end

    context 'when merge request is present' do
      let_it_be(:assignees) { create_list(:user, 2) }
      let_it_be(:milestone) { create(:milestone, project: project) }
      let_it_be(:labels) { create_list(:label, 2) }
      let(:merge_request_description) { nil }

      let(:merge_request) do
        create(:merge_request, :simple,
          source_project: project,
          target_project: project,
          assignees: assignees,
          milestone: milestone,
          description: merge_request_description,
          labels: labels)
      end

      context 'when pipeline for merge request is created' do
        let(:pipeline) do
          create(:ci_pipeline, :detached_merge_request_pipeline,
            ci_ref_presence: false,
            user: user,
            merge_request: merge_request)
        end

        before do
          project.add_developer(user)
        end

        it 'exposes merge request pipeline variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_ID' => merge_request.id.to_s,
              'CI_MERGE_REQUEST_IID' => merge_request.iid.to_s,
              'CI_MERGE_REQUEST_REF_PATH' => merge_request.ref_path.to_s,
              'CI_MERGE_REQUEST_PROJECT_ID' => merge_request.project.id.to_s,
              'CI_MERGE_REQUEST_PROJECT_PATH' => merge_request.project.full_path,
              'CI_MERGE_REQUEST_PROJECT_URL' => merge_request.project.web_url,
              'CI_MERGE_REQUEST_TARGET_BRANCH_NAME' => merge_request.target_branch.to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED' => ProtectedBranch.protected?(
                merge_request.target_project,
                merge_request.target_branch
              ).to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_SHA' => '',
              'CI_MERGE_REQUEST_SOURCE_PROJECT_ID' => merge_request.source_project.id.to_s,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH' => merge_request.source_project.full_path,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_URL' => merge_request.source_project.web_url,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => merge_request.source_branch.to_s,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => '',
              'CI_MERGE_REQUEST_SOURCE_BRANCH_PROTECTED' => ProtectedBranch.protected?(
                merge_request.source_project,
                merge_request.source_branch
              ).to_s,
              'CI_MERGE_REQUEST_TITLE' => merge_request.title,
              'CI_MERGE_REQUEST_DESCRIPTION' => merge_request.description,
              'CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED' => 'false',
              'CI_MERGE_REQUEST_ASSIGNEES' => merge_request.assignee_username_list,
              'CI_MERGE_REQUEST_MILESTONE' => milestone.title,
              'CI_MERGE_REQUEST_LABELS' => labels.map(&:title).sort.join(','),
              'CI_MERGE_REQUEST_EVENT_TYPE' => 'detached',
              'CI_OPEN_MERGE_REQUESTS' => merge_request.to_reference(full: true)),
              'CI_MERGE_REQUEST_SQUASH_ON_MERGE' => merge_request.squash_on_merge?.to_s
        end

        context 'when merge request description hits the limit' do
          let(:merge_request_description) { 'a' * (MergeRequest::CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH + 1) }

          it 'truncates the exposed description' do
            truncated_description = merge_request.description.truncate(
              MergeRequest::CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH
            )
            expect(subject.to_hash)
              .to include(
                'CI_MERGE_REQUEST_DESCRIPTION' => truncated_description,
                'CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED' => 'true'
              )
          end
        end

        context 'when merge request description fits the length limit' do
          let(:merge_request_description) { 'a' * (MergeRequest::CI_MERGE_REQUEST_DESCRIPTION_MAX_LENGTH - 1) }

          it 'does not truncate the exposed description' do
            expect(subject.to_hash)
              .to include(
                'CI_MERGE_REQUEST_DESCRIPTION' => merge_request.description,
                'CI_MERGE_REQUEST_DESCRIPTION_IS_TRUNCATED' => 'false'
              )
          end
        end

        it 'exposes diff variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_DIFF_ID' => merge_request.merge_request_diff.id.to_s,
              'CI_MERGE_REQUEST_DIFF_BASE_SHA' => merge_request.merge_request_diff.base_commit_sha)
        end

        context 'without assignee' do
          let(:assignees) { [] }

          it 'does not expose assignee variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_ASSIGNEES')
          end
        end

        context 'without milestone' do
          let(:milestone) { nil }

          it 'does not expose milestone variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_MILESTONE')
          end
        end

        context 'without labels' do
          let(:labels) { [] }

          it 'does not expose labels variable' do
            expect(subject.to_hash.keys).not_to include('CI_MERGE_REQUEST_LABELS')
          end
        end
      end

      context 'when pipeline on branch is created' do
        let(:pipeline) do
          create(:ci_pipeline, project: project, user: user, ref: 'feature')
        end

        context 'when a merge request is created' do
          before do
            merge_request
          end

          context 'when user has access to project' do
            before do
              project.add_developer(user)
            end

            it 'merge request references are returned matching the pipeline' do
              expect(subject.to_hash).to include(
                'CI_OPEN_MERGE_REQUESTS' => merge_request.to_reference(full: true))
            end
          end

          context 'when user does not have access to project' do
            it 'CI_OPEN_MERGE_REQUESTS is not returned' do
              expect(subject.to_hash).not_to have_key('CI_OPEN_MERGE_REQUESTS')
            end
          end
        end

        context 'when no a merge request is created' do
          it 'CI_OPEN_MERGE_REQUESTS is not returned' do
            expect(subject.to_hash).not_to have_key('CI_OPEN_MERGE_REQUESTS')
          end
        end
      end

      context 'with merged results' do
        let(:pipeline) do
          create(:ci_pipeline, :merged_result_pipeline, merge_request: merge_request)
        end

        it 'exposes merge request pipeline variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_ID' => merge_request.id.to_s,
              'CI_MERGE_REQUEST_IID' => merge_request.iid.to_s,
              'CI_MERGE_REQUEST_REF_PATH' => merge_request.ref_path.to_s,
              'CI_MERGE_REQUEST_PROJECT_ID' => merge_request.project.id.to_s,
              'CI_MERGE_REQUEST_PROJECT_PATH' => merge_request.project.full_path,
              'CI_MERGE_REQUEST_PROJECT_URL' => merge_request.project.web_url,
              'CI_MERGE_REQUEST_TARGET_BRANCH_NAME' => merge_request.target_branch.to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_PROTECTED' => ProtectedBranch.protected?(
                merge_request.target_project,
                merge_request.target_branch
              ).to_s,
              'CI_MERGE_REQUEST_TARGET_BRANCH_SHA' => merge_request.target_branch_sha,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_ID' => merge_request.source_project.id.to_s,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_PATH' => merge_request.source_project.full_path,
              'CI_MERGE_REQUEST_SOURCE_PROJECT_URL' => merge_request.source_project.web_url,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_NAME' => merge_request.source_branch.to_s,
              'CI_MERGE_REQUEST_SOURCE_BRANCH_SHA' => merge_request.source_branch_sha,
              'CI_MERGE_REQUEST_TITLE' => merge_request.title,
              'CI_MERGE_REQUEST_DESCRIPTION' => merge_request.description,
              'CI_MERGE_REQUEST_ASSIGNEES' => merge_request.assignee_username_list,
              'CI_MERGE_REQUEST_MILESTONE' => milestone.title,
              'CI_MERGE_REQUEST_LABELS' => labels.map(&:title).sort.join(','),
              'CI_MERGE_REQUEST_EVENT_TYPE' => 'merged_result')
        end

        it 'exposes diff variables' do
          expect(subject.to_hash)
            .to include(
              'CI_MERGE_REQUEST_DIFF_ID' => merge_request.merge_request_diff.id.to_s,
              'CI_MERGE_REQUEST_DIFF_BASE_SHA' => merge_request.merge_request_diff.base_commit_sha)
        end
      end
    end

    context 'when source is external pull request' do
      let(:pipeline) do
        create(:ci_pipeline, source: :external_pull_request_event, external_pull_request: pull_request)
      end

      let(:pull_request) { create(:external_pull_request, project: project) }

      it 'exposes external pull request pipeline variables' do
        expect(subject.to_hash)
          .to include(
            'CI_EXTERNAL_PULL_REQUEST_IID' => pull_request.pull_request_iid.to_s,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_REPOSITORY' => pull_request.source_repository,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_REPOSITORY' => pull_request.target_repository,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_SHA' => pull_request.source_sha,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_SHA' => pull_request.target_sha,
            'CI_EXTERNAL_PULL_REQUEST_SOURCE_BRANCH_NAME' => pull_request.source_branch,
            'CI_EXTERNAL_PULL_REQUEST_TARGET_BRANCH_NAME' => pull_request.target_branch
          )
      end
    end

    context 'when source is a pipeline schedule' do
      let_it_be(:pipeline_schedule) { create(:ci_pipeline_schedule, project: project) }
      let_it_be(:pipeline) { create(:ci_pipeline, pipeline_schedule: pipeline_schedule, project: project) }

      it 'exposes the pipeline schedule description variable' do
        expect(subject.to_hash)
          .to include(
            'CI_PIPELINE_SCHEDULE_DESCRIPTION' => pipeline.pipeline_schedule.description
          )
      end
    end

    describe 'variable CI_KUBERNETES_ACTIVE' do
      context 'when pipeline.has_kubernetes_active? is true' do
        before do
          allow(pipeline).to receive(:has_kubernetes_active?).and_return(true)
        end

        it "is included with value 'true'" do
          expect(subject.to_hash).to include('CI_KUBERNETES_ACTIVE' => 'true')
        end
      end

      context 'when pipeline.has_kubernetes_active? is false' do
        before do
          allow(pipeline).to receive(:has_kubernetes_active?).and_return(false)
        end

        it 'is not included' do
          expect(subject.to_hash).not_to have_key('CI_KUBERNETES_ACTIVE')
        end
      end
    end

    describe 'variable CI_GITLAB_FIPS_MODE' do
      context 'when FIPS flag is enabled' do
        before do
          allow(Gitlab::FIPS).to receive(:enabled?).and_return(true)
        end

        it "is included with value 'true'" do
          expect(subject.to_hash).to include('CI_GITLAB_FIPS_MODE' => 'true')
        end
      end

      context 'when FIPS flag is disabled' do
        before do
          allow(Gitlab::FIPS).to receive(:enabled?).and_return(false)
        end

        it 'is not included' do
          expect(subject.to_hash).not_to have_key('CI_GITLAB_FIPS_MODE')
        end
      end
    end

    context 'when tag is not found' do
      let(:pipeline) do
        create(:ci_pipeline, project: project, ref: 'not_found_tag', tag: true)
      end

      it 'does not expose tag variables' do
        expect(subject.to_hash.keys)
          .not_to include(
            'CI_COMMIT_TAG',
            'CI_COMMIT_TAG_MESSAGE'
          )
      end
    end

    context 'without a commit' do
      let(:pipeline) { build(:ci_empty_pipeline, :created, sha: nil) }

      it 'does not expose commit variables' do
        expect(subject.to_hash.keys)
          .not_to include(
            'CI_COMMIT_SHA',
            'CI_COMMIT_SHORT_SHA',
            'CI_COMMIT_BEFORE_SHA',
            'CI_COMMIT_REF_NAME',
            'CI_COMMIT_REF_SLUG',
            'CI_COMMIT_BRANCH',
            'CI_COMMIT_TAG',
            'CI_COMMIT_MESSAGE',
            'CI_COMMIT_TITLE',
            'CI_COMMIT_DESCRIPTION',
            'CI_COMMIT_REF_PROTECTED',
            'CI_COMMIT_TIMESTAMP',
            'CI_COMMIT_AUTHOR')
      end
    end
  end
end
