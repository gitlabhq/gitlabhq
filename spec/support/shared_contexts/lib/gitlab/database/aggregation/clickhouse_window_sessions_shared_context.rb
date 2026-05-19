# frozen_string_literal: true

# Shared 3-day agent_platform_sessions fixture data for window-metric specs
# (lagged_count, retained_count). Produces users-per-day:
#
#   Day 1 (2025-03-01): users (1, 2) - both chat
#   Day 2 (2025-03-02): user 1 (chat), user 3 (code_review)
#   Day 3 (2025-03-03): user 2 (chat)
RSpec.shared_context 'with 3-day agent_platform_sessions window data' do
  def window_session(session_id:, user_id:, date:, flow_type:, duration:)
    created_at = DateTime.parse("#{date} 00:00:00 UTC")
    { session_id: session_id, user_id: user_id, project_id: 1, namespace_path: '1/2/',
      flow_type: flow_type, environment: 'prod', session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + duration }
  end

  let(:session1) do
    window_session(session_id: 1, user_id: 1, date: '2025-03-01', flow_type: 'chat', duration: 10.minutes)
  end

  let(:session2) do
    window_session(session_id: 2, user_id: 2, date: '2025-03-01', flow_type: 'chat', duration: 3.minutes)
  end

  let(:session3) do
    window_session(session_id: 3, user_id: 1, date: '2025-03-02', flow_type: 'chat', duration: 5.minutes)
  end

  let(:session4) do
    window_session(session_id: 4, user_id: 3, date: '2025-03-02', flow_type: 'code_review', duration: 2.minutes)
  end

  let(:session5) do
    window_session(session_id: 5, user_id: 2, date: '2025-03-03', flow_type: 'chat', duration: 4.minutes)
  end

  let(:all_data_rows) { [session1, session2, session3, session4, session5] }
end
