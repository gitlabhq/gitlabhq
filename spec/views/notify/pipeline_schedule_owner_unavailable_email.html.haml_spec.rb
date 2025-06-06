# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/pipeline_schedule_owner_unavailable_email.html.haml', feature_category: :continuous_integration do
  let_it_be(:project) { build_stubbed(:project, :repository) }
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:schedule) { build_stubbed(:ci_pipeline_schedule, project: project, description: 'Daily deployment') }

  before do
    assign(:schedule, schedule)
    assign(:project, schedule.project)
    assign(:recipient, user)
  end

  it 'displays the pipeline schedule information' do
    render

    expect(rendered).to have_text("The owner of the pipeline schedule")
    expect(rendered).to have_text("no longer has permission.")
    expect(rendered).to have_text(
      "Without an owner, the pipeline will not run. Take ownership so the pipeline runs on schedule.")
  end

  it 'includes pipeline_schedule and documentation links' do
    render

    expect(rendered).to have_link(schedule.description, href: project_pipeline_schedule_url(schedule.project, schedule))
    expect(rendered).to have_link(
      "Learn how to take ownership.",
      href: help_page_url('ci/pipelines/schedules.md', anchor: 'take-ownership')
    )
  end

  context 'when url helpers are functioning properly' do
    it 'generates the correct pipeline schedule URL' do
      expected_url = project_pipeline_schedule_url(schedule.project, schedule)

      expect(expected_url).to include(project.full_path)
      expect(expected_url).to include('pipeline_schedules')
      expect(expected_url).to include(schedule.id.to_s)
    end
  end
end
