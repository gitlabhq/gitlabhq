# frozen_string_literal: true

RSpec.configure do |config|
  config.before do
    if Gitlab::Database.postgresql? && ENV['PG_STAT_WARNING_THRESHOLD']
      warning_threshold = ENV['PG_STAT_WARNING_THRESHOLD'].to_i
      results = ActiveRecord::Base.connection.execute('SELECT * FROM pg_stat_activity')
      ntuples = results.ntuples

      warn("pg_stat_activity count: #{ntuples}")

      if ntuples > warning_threshold
        results.each do |result|
          warn result.inspect
        end
      end
    end
  end
end
