# frozen_string_literal: true
shared_examples 'N+1 query check' do
  it 'prevents N+1 queries' do
    execute_query # "warm up" to prevent undeterministic counts

    control_count = ActiveRecord::QueryRecorder.new { execute_query }.count

    search_params[:iids] << extra_iid_for_second_query
    expect { execute_query }.not_to exceed_query_limit(control_count)
  end
end
