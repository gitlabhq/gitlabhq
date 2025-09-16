# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'notify/pipeline_schedule_owner_unavailable_email.text.erb', feature_category: :continuous_integration do
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
      "The schedule is deactivated and cannot run. Take ownership and reactivate the schedule to resume pipeline runs."
    )
  end

  it 'includes pipeline_schedule and documentation links' do
    render

    pipeline_schedule_url = project_pipeline_schedule_url(schedule.project, schedule)
    documentation_url = help_page_url('ci/pipelines/schedules.md', anchor: 'take-ownership')

    expect(rendered).to include(pipeline_schedule_url)
    expect(rendered).to include("Learn how to take ownership: #{documentation_url}")
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
