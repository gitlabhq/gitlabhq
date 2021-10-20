# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::PerformanceBar::Stats do
  describe '#process' do
    let(:request) { fixture_file('lib/gitlab/performance_bar/peek_data.json') }
    let(:redis) { double(Gitlab::Redis::SharedState) }
    let(:logger) { double(Gitlab::PerformanceBar::Logger) }
    let(:request_id) { 'foo' }
    let(:stats) { described_class.new(redis) }

    describe '#process' do
      subject(:process) { stats.process(request_id) }

      before do
        allow(stats).to receive(:logger).and_return(logger)
      end

      it 'logs each SQL query including its duration' do
        allow(redis).to receive(:get).and_return(request)

        expect(logger).to receive(:info)
          .with({ duration_ms: 1.096, filename: 'lib/gitlab/pagination/offset_pagination.rb',
                  method_path: 'lib/gitlab/pagination/offset_pagination.rb:add_pagination_headers',
                  count: 1, request_id: 'foo', query_type: 'active-record' })
        expect(logger).to receive(:info)
          .with({ duration_ms: 1.634, filename: 'lib/api/helpers.rb',
                  method_path: 'lib/api/helpers.rb:find_project',
                  count: 2, request_id: 'foo', query_type: 'active-record' })
        expect(logger).to receive(:info)
          .with({ duration_ms: 23.709, filename: 'lib/gitlab/gitaly_client/commit_service.rb',
                  method_path: 'lib/gitlab/gitaly_client/commit_service.rb:each',
                  count: 1, request_id: 'foo', query_type: 'gitaly' })
        expect(logger).to receive(:info)
          .with({ duration_ms: 6.678, filename: 'lib/gitlab/gitaly_client/commit_service.rb',
                  method_path: 'lib/gitlab/gitaly_client/commit_service.rb:call_find_commit',
                  count: 1, request_id: 'foo', query_type: 'gitaly' })
        expect(logger).to receive(:info)
          .with({ duration_ms: 0.155, filename: 'lib/feature.rb',
                  method_path: 'lib/feature.rb:enabled?',
                  count: 1, request_id: 'foo', query_type: 'redis' })

        subject
      end

      it 'logs an error when the request could not be processed' do
        allow(redis).to receive(:get).and_return(nil)

        expect(logger).to receive(:error).with(message: anything)

        subject
      end
    end
  end
end
