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
  end
end
