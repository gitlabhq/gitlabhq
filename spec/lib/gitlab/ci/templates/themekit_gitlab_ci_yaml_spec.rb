# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ThemeKit.gitlab-ci.yml', feature_category: :continuous_integration do
  include Ci::PipelineMessageHelpers

  before do
    allow(Gitlab::Template::GitlabCiYmlTemplate).to receive(:excluded_patterns).and_return([])
  end

  subject(:template) { Gitlab::Template::GitlabCiYmlTemplate.find('ThemeKit') }

  describe 'the created pipeline' do
    let(:pipeline_ref) { project.default_branch_or_main }
    let(:project) { create(:project, :custom_repo, files: { 'README.md' => '' }) }
    let(:user) { project.first_owner }
    let(:service) { Ci::CreatePipelineService.new(project, user, ref: pipeline_ref) }
    let(:pipeline) { service.execute(:push).payload }
    let(:build_names) { pipeline.builds.pluck(:name) }

    before do
      stub_ci_pipeline_yaml_file(template.content)
    end

    context 'on the default branch' do
      it 'only creates staging deploy', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).to include('staging')
        expect(build_names).not_to include('production')
      end
    end

    context 'on a tag' do
      let(:pipeline_ref) { '1.0' }

      before do
        project.repository.add_tag(user, pipeline_ref, project.default_branch_or_main)
      end

      it 'only creates a production deploy', :aggregate_failures do
        expect(pipeline.errors).to be_empty
        expect(build_names).to include('production')
        expect(build_names).not_to include('staging')
      end
    end

    context 'outside of the default branch' do
      let(:pipeline_ref) { 'patch-1' }

      before do
        project.repository.create_branch(pipeline_ref, project.default_branch_or_main)
      end

      it 'has no jobs' do
        expect(build_names).to be_empty
        expect(pipeline.errors.full_messages).to match_array([sanitize_message(Ci::Pipeline.rules_failure_message)])
      end
    end
  end
end
