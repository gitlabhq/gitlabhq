# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/jobs/show' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:build) { create(:ci_build, pipeline: pipeline) }
  let(:builds) { project.builds.present(current_user: user) }

  let(:pipeline) do
    create(:ci_pipeline, project: project, sha: project.commit.id)
  end

  before do
    assign(:build, build.present)
    assign(:project, project)
    assign(:builds, builds)

    allow(view).to receive(:can?).and_return(true)
  end

  context 'when job is running' do
    let(:build) { create(:ci_build, :trace_live, :running, pipeline: pipeline) }

    before do
      render
    end

    it 'does not show retry button' do
      expect(rendered).not_to have_link('Retry')
    end

    it 'does not show New issue button' do
      expect(rendered).not_to have_link('New issue')
    end
  end
end
