# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  let(:project) { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
  let(:pipeline) { create(:ci_empty_pipeline, project: project) }
  let(:user) { create(:user) }

  let(:request) { double('request', current_user: user, project: project) }

  subject do
    described_class.new(resource, request: request).as_json
  end

  describe 'source_project_full_path' do
    it 'includes the full path of the source project' do
      expect(subject[:source_project_full_path]).to be_present
    end

    context 'when the source project is missing' do
      it 'returns `nil` for the source project' do
        resource.allow_broken = true
        resource.update!(source_project: nil)

        expect(subject[:source_project_full_path]).to be_nil
      end
    end
  end

  describe 'can_create_pipeline_in_target_project' do
    context 'when user has permission' do
      before do
        project.add_developer(user)
      end

      it 'includes the correct permission info' do
        expect(subject[:can_create_pipeline_in_target_project]).to eq(true)
      end
    end

    context 'when user does not have permission' do
      before do
        project.add_guest(user)
      end

      it 'includes the correct permission info' do
        expect(subject[:can_create_pipeline_in_target_project]).to eq(false)
      end
    end
  end

  describe 'issues links' do
    it 'includes issues links when requested' do
      data = described_class.new(resource, request: request, issues_links: true).as_json

      expect(data).to include(:issues_links)
      expect(data[:issues_links]).to include(:assign_to_closing, :closing, :mentioned_but_not_closing)
    end

    it 'omits issue links by default' do
      expect(subject).not_to include(:issues_links)
    end
  end

  it 'has email_patches_path' do
    expect(subject[:email_patches_path])
      .to eq("/#{resource.project.full_path}/-/merge_requests/#{resource.iid}.patch")
  end

  it 'has plain_diff_path' do
    expect(subject[:plain_diff_path])
      .to eq("/#{resource.project.full_path}/-/merge_requests/#{resource.iid}.diff")
  end

  it 'has blob path data' do
    allow(resource).to receive_messages(
      base_pipeline: pipeline,
      head_pipeline: pipeline
    )

    expect(subject).to include(:blob_path)
    expect(subject[:blob_path]).to include(:base_path)
    expect(subject[:blob_path]).to include(:head_path)
  end

  describe 'codequality report artifacts', :request_store do
    let(:merge_base_pipeline) { create(:ci_pipeline, :with_codequality_report, project: project) }

    before do
      project.add_developer(user)

      allow(resource).to receive_messages(
        merge_base_pipeline: merge_base_pipeline,
        base_pipeline: pipeline,
        head_pipeline: pipeline
      )
    end

    context 'with report artifacts' do
      let(:pipeline) { create(:ci_pipeline, :with_codequality_report, project: project) }
      let(:generic_job_id) { pipeline.builds.first.id }
      let(:merge_base_job_id) { merge_base_pipeline.builds.first.id }

      it 'has head_path and base_path entries' do
        expect(subject[:codeclimate][:head_path]).to include("/jobs/#{generic_job_id}/artifacts/download?file_type=codequality")
        expect(subject[:codeclimate][:base_path]).to include("/jobs/#{generic_job_id}/artifacts/download?file_type=codequality")
      end

      context 'on pipelines for merged results' do
        let(:pipeline) { create(:ci_pipeline, :merged_result_pipeline, :with_codequality_report, project: project) }

        it 'returns URLs from the head_pipeline and merge_base_pipeline' do
          expect(subject[:codeclimate][:head_path]).to include("/jobs/#{generic_job_id}/artifacts/download?file_type=codequality")
          expect(subject[:codeclimate][:base_path]).to include("/jobs/#{merge_base_job_id}/artifacts/download?file_type=codequality")
        end
      end
    end

    context 'without artifacts' do
      it 'does not have data entry' do
        expect(subject).not_to include(:codeclimate)
      end
    end
  end

  describe 'merge_request_add_ci_config_path' do
    let!(:project_auto_devops) { create(:project_auto_devops, :disabled, project: project) }

    before do
      project.add_role(user, role)
    end

    context 'when there is a standard ci config file in the source project' do
      let(:role) { :developer }

      before do
        project.repository.create_file(user, Gitlab::FileDetector::PATTERNS[:gitlab_ci], 'CONTENT', message: 'Add .gitlab-ci.yml', branch_name: 'master')
      end

      it 'no ci config path' do
        expect(subject[:merge_request_add_ci_config_path]).to be_nil
      end
    end

    context 'when there is no standard ci config file in the source project' do
      context 'when user has permissions' do
        let(:role) { :developer }

        it 'has add ci config path' do
          expected_path = "/#{resource.project.full_path}/-/new/#{resource.source_branch}"

          expect(subject[:merge_request_add_ci_config_path]).to include(expected_path)
        end

        it 'has expected params' do
          expected_params = {
            commit_message: 'Add .gitlab-ci.yml',
            file_name: '.gitlab-ci.yml',
            suggest_gitlab_ci_yml: 'true',
            mr_path: "/#{resource.project.full_path}/-/merge_requests/#{resource.iid}"
          }.with_indifferent_access

          uri = Addressable::URI.parse(subject[:merge_request_add_ci_config_path])

          expect(uri.query_values).to match(expected_params)
        end

        context 'when auto devops is enabled' do
          before do
            project_auto_devops.enabled = true
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when source project is missing' do
          before do
            resource.source_project = nil
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when there are no commits' do
          before do
            allow(resource).to receive(:commits_count).and_return(0)
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when ci_config_path is customized' do
          it 'has no path if ci_config_path is not set to our default setting' do
            project.ci_config_path = 'not_default'

            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end

          it 'has a path if ci_config_path unset' do
            expect(subject[:merge_request_add_ci_config_path]).not_to be_nil
          end

          it 'has a path if ci_config_path is an empty string' do
            project.ci_config_path = ''

            expect(subject[:merge_request_add_ci_config_path]).not_to be_nil
          end

          it 'has a path if ci_config_path is set to our default file' do
            project.ci_config_path = Gitlab::FileDetector::PATTERNS[:gitlab_ci]

            expect(subject[:merge_request_add_ci_config_path]).not_to be_nil
          end
        end

        context 'when build feature is disabled' do
          before do
            project.project_feature.update!(builds_access_level: ProjectFeature::DISABLED)
          end

          it 'has no path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when creating the pipeline is not allowed' do
          before do
            user.state = 'blocked'
          end

          it 'has no path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when merge request is merged' do
          before do
            resource.mark_as_merged!
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when merge request is closed' do
          before do
            resource.close!
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end

        context 'when source branch does not exist' do
          before do
            resource.source_project.repository.rm_branch(user, resource.source_branch)
          end

          it 'returns a blank ci config path' do
            expect(subject[:merge_request_add_ci_config_path]).to be_nil
          end
        end
      end

      context 'when user does not have permissions' do
        let(:role) { :reporter }

        it 'has add ci config path' do
          expect(subject[:merge_request_add_ci_config_path]).to be_nil
        end
      end
    end
  end

  describe 'user callouts' do
    subject { described_class.new(resource, request: request).as_json }

    it 'provides a valid path value for user callout path' do
      expect(subject[:user_callouts_path]).to eq '/-/user_callouts'
    end

    it 'provides a valid value for suggest pipeline feature id' do
      expect(subject[:suggest_pipeline_feature_id]).to eq described_class::SUGGEST_PIPELINE
    end

    it 'provides a valid value for if it is dismissed' do
      expect(subject[:is_dismissed_suggest_pipeline]).to be(false)
    end

    context 'when the suggest pipeline has been dismissed' do
      before do
        create(:user_callout, user: user, feature_name: described_class::SUGGEST_PIPELINE)
      end

      it 'indicates suggest pipeline has been dismissed' do
        expect(subject[:is_dismissed_suggest_pipeline]).to be(true)
      end
    end

    context 'when user is not logged in' do
      let(:request) { double('request', current_user: nil, project: project) }

      it 'returns a blank is dismissed value' do
        expect(subject[:is_dismissed_suggest_pipeline]).to be_nil
      end
    end
  end

  it 'has human access' do
    project.add_maintainer(user)

    expect(subject[:human_access])
      .to eq('Maintainer')
  end

  it 'has new pipeline path for project' do
    project.add_maintainer(user)

    expect(subject[:new_project_pipeline_path])
      .to eq("/#{resource.project.full_path}/-/pipelines/new")
  end

  describe 'when source project is deleted' do
    let(:project) { create(:project, :repository) }
    let(:forked_project) { fork_project(project) }
    let(:merge_request) { create(:merge_request, source_project: forked_project, target_project: project) }

    it 'returns a blank rebase_path' do
      allow(merge_request).to receive(:should_be_rebased?).and_return(true)
      forked_project.destroy!
      merge_request.reload

      entity = described_class.new(merge_request, request: request).as_json

      expect(entity[:rebase_path]).to be_nil
    end
  end

  it 'has security_reports_docs_path' do
    expect(subject[:security_reports_docs_path]).not_to be_nil
  end

  describe 'has source_project_default_url' do
    it 'returns the default url to the source project' do
      expect(subject[:source_project_default_url]).to eq project.http_url_to_repo
    end

    context 'when source project is nil' do
      it 'returns nil' do
        allow(resource).to receive(:source_project).and_return(nil)

        expect(subject[:source_project_default_url]).to be_nil
      end
    end
  end
end
