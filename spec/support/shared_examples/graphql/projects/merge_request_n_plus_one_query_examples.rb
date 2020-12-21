# frozen_string_literal: true
shared_examples 'N+1 query check' do
  it 'prevents N+1 queries' do
    execute_query # "warm up" to prevent undeterministic counts
    expect(graphql_errors).to be_blank # Sanity check - ex falso quodlibet!

    control = ActiveRecord::QueryRecorder.new { execute_query }
    expect(control.count).to be > 0

    search_params[:iids] << extra_iid_for_second_query
    expect { execute_query }.not_to exceed_query_limit(control)
  end
end
