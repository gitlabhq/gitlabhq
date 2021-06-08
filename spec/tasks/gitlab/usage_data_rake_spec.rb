# frozen_string_literal: true

require 'rake_helper'

RSpec.describe 'gitlab:usage data take tasks', :silence_stdout do
  include UsageDataHelpers

  before do
    Rake.application.rake_require 'tasks/gitlab/usage_data'
    # stub prometheus external http calls https://gitlab.com/gitlab-org/gitlab/-/issues/245277
    stub_prometheus_queries
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
