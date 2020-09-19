# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:usage data take tasks' do
  before do
    Rake.application.rake_require 'tasks/gitlab/usage_data'
    # stub prometheus external http calls https://gitlab.com/gitlab-org/gitlab/-/issues/245277
    stub_request(:get, %r{^http[s]?://::1:9090/-/ready})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    stub_request(:get, %r{^http[s]?://::1:9090/api/v1/query\?query=.*})
      .to_return(
        status: 200,
        body: [{}].to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  describe 'dump_sql_in_yaml' do
    it 'dumps SQL queries in yaml format' do
      expect { run_rake_task('gitlab:usage_data:dump_sql_in_yaml') }.to output(/.*recorded_at:.*/).to_stdout
    end
  end

  describe 'dump_sql_in_json' do
    it 'dumps SQL queries in json format' do
      expect { run_rake_task('gitlab:usage_data:dump_sql_in_json') }.to output(/.*"recorded_at":.*/).to_stdout
    end
  end
end
