# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BacktraceCleaner do
  describe '.clean_backtrace' do
    it 'uses the Rails backtrace cleaner' do
      backtrace = []

      expect(Rails.backtrace_cleaner).to receive(:clean).with(backtrace)

      described_class.clean_backtrace(backtrace)
    end

    it 'removes lines from IGNORE_BACKTRACES' do
      backtrace = [
        "lib/gitlab/gitaly_client.rb:294:in `block (2 levels) in migrate'",
        "lib/gitlab/gitaly_client.rb:331:in `allow_n_plus_1_calls'",
        "lib/gitlab/gitaly_client.rb:280:in `block in migrate'",
        "lib/gitlab/metrics/influx_db.rb:103:in `measure'",
        "lib/gitlab/gitaly_client.rb:278:in `migrate'",
        "lib/gitlab/git/repository.rb:1451:in `gitaly_migrate'",
        "lib/gitlab/git/commit.rb:66:in `find'",
        "app/models/repository.rb:1047:in `find_commit'",
        "lib/gitlab/metrics/instrumentation.rb:159:in `block in find_commit'",
        "lib/gitlab/metrics/method_call.rb:36:in `measure'",
        "lib/gitlab/metrics/instrumentation.rb:159:in `find_commit'",
        "app/models/repository.rb:113:in `commit'",
        "lib/gitlab/i18n.rb:50:in `with_locale'",
        "lib/gitlab/middleware/multipart.rb:95:in `call'",
        "lib/gitlab/request_profiler/middleware.rb:14:in `call'",
        "ee/lib/gitlab/database/load_balancing/rack_middleware.rb:37:in `call'",
        "ee/lib/gitlab/jira/middleware.rb:15:in `call'"
      ]

      expect(described_class.clean_backtrace(backtrace))
        .to eq([
                 "lib/gitlab/gitaly_client.rb:294:in `block (2 levels) in migrate'",
                 "lib/gitlab/gitaly_client.rb:331:in `allow_n_plus_1_calls'",
                 "lib/gitlab/gitaly_client.rb:280:in `block in migrate'",
                 "lib/gitlab/gitaly_client.rb:278:in `migrate'",
                 "lib/gitlab/git/repository.rb:1451:in `gitaly_migrate'",
                 "lib/gitlab/git/commit.rb:66:in `find'",
                 "app/models/repository.rb:1047:in `find_commit'",
                 "app/models/repository.rb:113:in `commit'",
                 "ee/lib/gitlab/jira/middleware.rb:15:in `call'"
               ])
    end
  end
end
