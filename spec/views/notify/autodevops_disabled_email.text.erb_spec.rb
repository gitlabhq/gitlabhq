# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/autodevops_disabled_email.text.erb' do
  include Devise::Test::ControllerHelpers

  let(:user) { create(:user, developer_of: project) }
  let(:project) { create(:project, :repository) }

  let(:pipeline) do
    create(
      :ci_pipeline,
      :failed,
      project: project,
      user: user,
      ref: project.default_branch,
      sha: project.commit.sha
    )
  end

  before do
    assign(:project, project)
    assign(:pipeline, pipeline)
  end

  context 'when the pipeline contains a failed job' do
    let!(:build) { create(:ci_build, :failed, :trace_live, pipeline: pipeline, project: pipeline.project) }

    it 'renders the email correctly' do
      render

      expect(rendered).to have_content("Auto DevOps pipeline was disabled for #{project.name}")
      expect(rendered).to match(/Pipeline ##{pipeline.id} .* triggered by #{pipeline.user.name}/)
      expect(rendered).to have_content("Stage: #{build.stage_name}")
      expect(rendered).to have_content("Name: #{build.name}")
      expect(rendered).not_to have_content("Trace:")
    end
  end
end
