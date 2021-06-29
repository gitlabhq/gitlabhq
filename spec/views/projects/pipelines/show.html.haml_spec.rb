# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/pipelines/show' do
  include Devise::Test::ControllerHelpers
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:pipeline) { create(:ci_pipeline, project: project) }
  let(:presented_pipeline) { pipeline.present(current_user: user) }

  before do
    assign(:project, project)
    assign(:pipeline, presented_pipeline)
  end

  context 'when pipeline has errors' do
    before do
      allow(pipeline).to receive(:yaml_errors).and_return('some errors')
    end

    it 'shows errors' do
      render

      expect(rendered).to have_content('Found errors in your .gitlab-ci.yml')
      expect(rendered).to have_content('some errors')
    end

    it 'does not render the pipeline tabs' do
      render

      expect(rendered).not_to have_css('ul.pipelines-tabs')
    end
  end

  context 'when pipeline is valid' do
    it 'does not show errors' do
      render

      expect(rendered).not_to have_content('Found errors in your .gitlab-ci.yml')
    end

    it 'renders the pipeline tabs' do
      render

      expect(rendered).to have_css('ul.pipelines-tabs')
    end
  end
end
