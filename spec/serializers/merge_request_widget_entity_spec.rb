# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestWidgetEntity, feature_category: :code_review_workflow do
  include ProjectForksHelper
  include Gitlab::Routing.url_helpers

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
      expect(data[:issues_links]).to include(:assign_to_closing, :assign_to_closing_count, :closing, :mentioned_but_not_closing, :closing_count, :mentioned_count)
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
        project.repository.create_file(user, project.ci_config_path_or_default, 'CONTENT', message: 'Add .gitlab-ci.yml', branch_name: 'master')
      end

      it 'no ci config path' do
        expect(subject[:merge_request_add_ci_config_path]).to be_nil
      end
    end

    context 'when there is no standard ci config file in the source project' do
      context 'when user has permissions' do
        let(:role) { :developer }

        it 'has add ci config path' do
          expected_path = project_ci_pipeline_editor_path(project)

          expect(subject[:merge_request_add_ci_config_path]).to include(expected_path)
        end

        it 'has expected params' do
          expected_params = {
            branch_name: resource.source_branch,
            add_new_config_file: 'true'
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
      expect(subject[:user_callouts_path]).to eq '/-/users/callouts'
    end

    it 'provides a valid value for suggest pipeline feature id' do
      expect(subject[:suggest_pipeline_feature_id]).to eq described_class::SUGGEST_PIPELINE
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

  describe 'when gitpod is disabled' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(false)
    end

    it 'exposes gitpod attributes' do
      expect(subject).to include(
        show_gitpod_button: false,
        gitpod_url: nil,
        gitpod_enabled: false
      )
    end
  end

  describe 'when gitpod is enabled' do
    before do
      allow(Gitlab::CurrentSettings).to receive(:gitpod_enabled).and_return(true)
      allow(Gitlab::CurrentSettings).to receive(:gitpod_url).and_return("https://gitpod.example.com")
    end

    it 'exposes gitpod attributes' do
      mr_url = Gitlab::Routing.url_helpers.project_merge_request_url(resource.project, resource)

      expect(subject).to include(
        show_gitpod_button: true,
        gitpod_url: "https://gitpod.example.com##{mr_url}",
        gitpod_enabled: false
      )
    end

    describe 'when gitpod is enabled for user' do
      before do
        allow(user).to receive(:gitpod_enabled).and_return(true)
      end

      it 'exposes gitpod_enabled as true' do
        expect(subject[:gitpod_enabled]).to be(true)
      end
    end
  end

  describe 'is_dismissed_suggest_pipeline' do
    context 'when user is logged in' do
      context 'when the suggest pipeline feature is enabled' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:suggest_pipeline_enabled?).and_return(true)
        end

        it 'is false' do
          expect(subject[:is_dismissed_suggest_pipeline]).to be(false)
        end

        context 'when suggest pipeline has been dismissed' do
          before do
            create(:callout, user: user, feature_name: described_class::SUGGEST_PIPELINE)
          end

          it 'is true' do
            expect(subject[:is_dismissed_suggest_pipeline]).to be(true)
          end
        end
      end

      context 'when the suggest pipeline feature is disabled' do
        before do
          allow(Gitlab::CurrentSettings).to receive(:suggest_pipeline_enabled?).and_return(false)
        end

        it 'is true' do
          expect(subject[:is_dismissed_suggest_pipeline]).to be(true)
        end
      end
    end

    context 'when user is not logged in' do
      let(:request) { double('request', current_user: nil, project: project) }

      it 'is true' do
        expect(subject[:is_dismissed_suggest_pipeline]).to be(true)
      end
    end
  end
end
