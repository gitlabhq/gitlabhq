# frozen_string_literal: true

require 'spec_helper'

describe MergeRequestWidgetEntity do
  include ProjectForksHelper

  let(:project) { create :project, :repository }
  let(:resource) { create(:merge_request, source_project: project, target_project: project) }
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
          expected_path = "/#{resource.project.full_path}/-/new/#{resource.source_branch}?commit_message=Add+.gitlab-ci.yml&file_name=.gitlab-ci.yml&suggest_gitlab_ci_yml=true"

          expect(subject[:merge_request_add_ci_config_path]).to eq(expected_path)
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
            project.project_feature.update(builds_access_level: ProjectFeature::DISABLED)
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
      end

      context 'when user does not have permissions' do
        let(:role) { :reporter }

        it 'has add ci config path' do
          expect(subject[:merge_request_add_ci_config_path]).to be_nil
        end
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
      forked_project.destroy
      merge_request.reload

      entity = described_class.new(merge_request, request: request).as_json

      expect(entity[:rebase_path]).to be_nil
    end
  end
end
