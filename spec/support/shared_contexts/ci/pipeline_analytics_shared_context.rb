# frozen_string_literal: true

RSpec.shared_context 'with pipelines executed on different projects' do
  let_it_be_with_reload(:project1) { create(:project) } # reload required to calculate traversal path
  let_it_be_with_reload(:project2) { create(:project) }
  let_it_be(:current_user) { create(:user, reporter_of: [project1, project2]) }

  let_it_be(:starting_time) { Time.utc(2023) }
  let_it_be(:ending_time) { 1.week.after(starting_time) }

  let(:pipelines) do
    [
      create_pipeline(project1, :success, ending_time, 30.minutes),                    # 2023-01-08
      create_pipeline(project1, :running, 35.minutes.before(ending_time), 30.minutes), # 2023-01-07
      create_pipeline(project1, :canceled, 1.hour.before(ending_time), 1.minute),      # 2023-01-07
      create_pipeline(project1, :success, 1.day.before(ending_time), 30.minutes),      # 2023-01-07
      create_pipeline(project1, :success, 1.5.days.before(ending_time), 3.days),       # 2023-01-06
      create_pipeline(project1, :failed, 5.days.before(ending_time), 2.hours),         # 2023-01-03
      create_pipeline(project1, :skipped, 5.days.before(ending_time), 1.second),       # 2023-01-03
      create_pipeline(project1, :canceled, 5.days.before(ending_time), 1.minute),      # 2023-01-03
      create_pipeline(project1, :failed, 1.week.before(ending_time), 45.minutes),      # 2023-01-01
      create_pipeline(project1, :skipped, 1.second.before(starting_time), 45.minutes)  # 2022-12-31
    ]
  end

  private

  def create_pipeline(project, status, started_at, duration)
    build_stubbed(:ci_pipeline, status,
      project: project,
      created_at: 1.second.before(started_at), started_at: started_at, finished_at: duration.after(started_at),
      duration: duration)
  end
end
