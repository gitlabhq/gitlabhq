# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pipelines/show', feature_category: :pipeline_composition do
  include Devise::Test::ControllerHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:presented_pipeline) { pipeline.present(current_user: user) }

  before do
    allow(view).to receive(:current_user) { user }
    assign(:project, project)
    assign(:pipeline, presented_pipeline)
  end

  context 'when pipeline has errors' do
    before do
      create(:ci_pipeline_message, pipeline: pipeline, content: 'some errors', severity: :error)
    end

    it 'shows errors' do
      render

      expect(rendered).to have_content('Unable to create pipeline')
      expect(rendered).to have_content('some errors')
    end

    it 'does not render the pipeline tabs' do
      render

      expect(rendered).not_to have_selector('#js-pipeline-tabs')
    end

    it 'renders the pipeline editor button with correct link for users who can view' do
      project.add_developer(user)

      render

      expect(rendered).to have_link s_('Go to the pipeline editor'),
        href: project_ci_pipeline_editor_path(project, branch_name: pipeline.source_ref)
    end

    it 'renders the pipeline editor button with correct link for users who can not view' do
      render

      expect(rendered).not_to have_link s_('Go to the pipeline editor'),
        href: project_ci_pipeline_editor_path(project, branch_name: pipeline.source_ref)
    end
  end

  context 'when pipeline does not have errors' do
    it 'does not show errors' do
      render

      expect(rendered).not_to have_content('Unable to create pipeline')
    end

    it 'renders the pipeline tabs' do
      render

      expect(rendered).to have_selector('#js-pipeline-tabs')
    end

    context 'when pipeline uses dependency scanning' do
      let(:build_name) { nil }
      let(:build) { create(:ci_build, name: build_name) }
      let(:pipeline) { create(:ci_pipeline, project: project, builds: [build]) }

      shared_examples 'pipeline with deprecated dependency scanning job' do
        it 'shows deprecation warning' do
          render

          expect(rendered).to have_content('You are using a deprecated Dependency Scanning analyzer')
          expect(rendered).to have_content(
            'The Gemnasium analyzer has been replaced with a new Dependency Scanning analyzer')
        end
      end

      context 'when gemnasium job is defined' do
        let(:build_name) { 'gemnasium' }

        it_behaves_like 'pipeline with deprecated dependency scanning job'
      end

      context 'when gemnasium-maven job is defined' do
        let(:build_name) { 'gemnasium-maven' }

        it_behaves_like 'pipeline with deprecated dependency scanning job'
      end

      context 'when gemnasium-python job is defined' do
        let(:build_name) { 'gemnasium-python' }

        it_behaves_like 'pipeline with deprecated dependency scanning job'
      end

      context 'when a gemnasium job is defined using parallel:matrix' do
        let(:build_name) { 'gemnasium: [variable]' }

        it_behaves_like 'pipeline with deprecated dependency scanning job'
      end

      context 'when a custom dependency scanning job is defined' do
        let(:build_name) { 'custom-govulncheck-dependency-scanning-job' }

        it 'shows deprecation warning' do
          render

          expect(rendered).not_to have_content('You are using a deprecated Dependency Scanning analyzer')
          expect(rendered).not_to have_content(
            'The Gemnasium analyzer has been replaced with a new Dependency Scanning analyzer')
        end
      end
    end
  end
end
