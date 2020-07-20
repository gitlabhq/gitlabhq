# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'projects/generic_commit_statuses/_generic_commit_status.html.haml' do
  include Devise::Test::ControllerHelpers

  let(:project) { create(:project, :repository) }
  let(:pipeline) { create(:ci_empty_pipeline, id: 1337, project: project, sha: project.commit.id) }
  let(:generic_commit_status) { create(:generic_commit_status, pipeline: pipeline, stage: 'external', name: 'jenkins', stage_idx: 3) }

  before do
    controller.prepend_view_path('app/views/projects')
    allow(view).to receive(:can?).and_return(true)
  end

  it 'won\'t include a column with a link to its pipeline by default' do
    render partial: 'projects/generic_commit_statuses/generic_commit_status', locals: { generic_commit_status: generic_commit_status }

    expect(rendered).not_to have_link('#1337')
    expect(rendered).not_to have_text('#1337 by API')
  end

  it 'can include a column with a link to its pipeline' do
    render partial: 'projects/generic_commit_statuses/generic_commit_status', locals: { generic_commit_status: generic_commit_status, pipeline_link: true }

    expect(rendered).to have_link('#1337')
    expect(rendered).to have_text('#1337 by API')
  end
end
