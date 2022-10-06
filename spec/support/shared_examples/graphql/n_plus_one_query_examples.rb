# frozen_string_literal: true

RSpec.shared_examples 'N+1 query check' do |threshold: 0, skip_cached: true|
  it 'prevents N+1 queries' do
    execute_query # "warm up" to prevent undeterministic counts
    expect(graphql_errors).to be_blank # Sanity check - ex falso quodlibet!

    control = ActiveRecord::QueryRecorder.new(skip_cached: skip_cached) { execute_query }
    expect(control.count).to be > 0

    search_params[:iids] << extra_iid_for_second_query

    expect { execute_query }.not_to exceed_query_count_limit(control, skip_cached: skip_cached, threshold: threshold)
  end

  def exceed_query_count_limit(control, skip_cached: true, threshold: 0)
    if skip_cached
      exceed_query_limit(control).with_threshold(threshold)
    else
      exceed_all_query_limit(control).with_threshold(threshold)
    end
  end
end
