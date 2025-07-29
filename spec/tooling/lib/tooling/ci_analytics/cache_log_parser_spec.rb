# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../../tooling/lib/tooling/ci_analytics/cache_log_parser'

RSpec.describe Tooling::CiAnalytics::CacheLogParser, feature_category: :tooling do
  describe '.extract_cache_events' do
    context 'with package registry operations' do
      let(:log_content) do
        <<~LOG
          2025-07-25T13:35:12.734729Z ** Fetching cached assets with assets hash 16ac23511b7abbf45496caa79ec34f27107a7ba209e6e46750ffd85ca12f4e8e **
          2025-07-25T13:35:15.234729Z The archive was not found. The server returned status 404.
          2025-07-25T13:35:16.234729Z Compiling frontend assets
          2025-07-25T13:35:45.234729Z gitlab:assets:fix_urls finished
        LOG
      end

      it 'extracts package registry miss events without crashing' do
        expect { described_class.extract_cache_events(log_content) }.not_to raise_error

        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(1)
        event = events.first
        expect(event[:cache_key]).to eq('assets-package-16ac23511b7a')
        expect(event[:cache_type]).to eq('assets-package')
        expect(event[:cache_operation]).to eq('pull')
        expect(event[:cache_result]).to eq('miss')
      end
    end

    context 'with standard cache operations' do
      let(:log_content) do
        <<~LOG
          2025-07-24T14:11:26.953582Z Checking cache for ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
          2025-07-24T14:11:35.382214Z Successfully extracted cache
          2025-07-24T14:11:46.639408Z Installing gems
          2025-07-24T14:11:50.334110Z Bundle complete!
        LOG
      end

      it 'extracts cache hit events' do
        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(1)
        event = events.first
        expect(event[:cache_key]).to eq('ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22')
        expect(event[:cache_type]).to eq('ruby-gems')
        expect(event[:cache_operation]).to eq('pull')
        expect(event[:cache_result]).to eq('hit')
        expect(event[:operation_command]).to eq('bundle install')
        expect(event[:operation_success]).to be(true)
      end
    end

    context 'with cache miss operations' do
      let(:log_content) do
        <<~LOG
          2025-07-24T14:11:26.953582Z Checking cache for node-modules-debian-bookworm-test-22...
          2025-07-24T14:11:35.382214Z WARNING: node-modules-debian-bookworm-test-22: not found
          2025-07-24T14:11:46.639408Z Installing Yarn packages
          2025-07-24T14:11:50.334110Z Done in 5.2s.
        LOG
      end

      it 'extracts cache miss events' do
        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(1)
        event = events.first
        expect(event[:cache_key]).to eq('node-modules-debian-bookworm-test-22')
        expect(event[:cache_type]).to eq('node-modules')
        expect(event[:cache_operation]).to eq('pull')
        expect(event[:cache_result]).to eq('miss')
        expect(event[:operation_command]).to eq('yarn install')
        expect(event[:operation_duration]).to eq(5.2)
      end
    end

    context 'with cache creation operations' do
      let(:log_content) do
        <<~LOG
          2025-07-24T14:11:26.953582Z Creating cache go-pkg-debian-bookworm-22...
          2025-07-24T14:11:50.334110Z Created cache
        LOG
      end

      it 'extracts cache creation events' do
        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(1)
        event = events.first
        expect(event[:cache_key]).to eq('go-pkg-debian-bookworm-22')
        expect(event[:cache_type]).to eq('go')
        expect(event[:cache_operation]).to eq('push')
        expect(event[:cache_result]).to eq('created')
      end
    end

    context 'with multiple cache operations' do
      let(:log_content) do
        <<~LOG
          2025-07-24T14:11:26.953582Z Checking cache for ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
          2025-07-24T14:11:35.382214Z Successfully extracted cache
          2025-07-24T14:11:35.403598Z Checking cache for rubocop-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
          2025-07-24T14:11:38.662550Z Successfully extracted cache
          2025-07-24T14:11:46.639408Z Installing gems
          2025-07-24T14:11:50.334110Z Bundle complete!
        LOG
      end

      it 'extracts multiple cache events correctly' do
        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(2)

        ruby_event = events.find { |e| e[:cache_type] == 'ruby-gems' }
        expect(ruby_event[:cache_result]).to eq('hit')
        expect(ruby_event[:operation_command]).to eq('bundle install')

        rubocop_event = events.find { |e| e[:cache_type] == 'rubocop' }
        expect(rubocop_event[:cache_result]).to eq('hit')
      end
    end

    context 'with logs without timestamps' do
      let(:log_content) do
        <<~LOG
          Checking cache for ruby-gems-test...
          Successfully extracted cache
        LOG
      end

      it 'handles logs without timestamps' do
        events = described_class.extract_cache_events(log_content)

        expect(events.size).to eq(1)
        expect(events.first[:cache_key]).to eq('ruby-gems-test')
      end
    end
  end

  describe '.parse_package_registry_operations' do
    let(:current_cache) { {} }
    let(:events) { [] }
    let(:timestamp) { Time.parse('2025-07-25T13:35:12.734729Z') }

    it 'handles fetching assets pattern' do
      assets_hash = "16ac23511b7abbf45496caa79ec34f27107a7ba209e6e46750ffd85ca12f4e8e"
      line = "** Fetching cached assets with assets hash #{assets_hash} **"

      expect { described_class.parse_package_registry_operations(line, timestamp, current_cache, events) }
        .not_to raise_error
    end

    it 'handles downloading package pattern' do
      line = "Downloading archive at https://gitlab.com/api/v4/projects/278964/packages/generic/assets/test-ee-hash/assets-test-ee-hash-v2.tar.gz..."
      current_cache[:cache_key] = 'test-package'

      described_class.parse_package_registry_operations(line, timestamp, current_cache, events)

      expect(current_cache[:cache_result]).to eq('hit')
    end

    it 'handles uploading package pattern' do
      line = "Uploading assets package"

      described_class.parse_package_registry_operations(line, timestamp, current_cache, events)

      expect(events.size).to eq(1)
      expect(events.first[:cache_operation]).to eq('push')
    end

    it 'handles package not found pattern' do
      line = "The archive was not found. The server returned status 404."
      current_cache[:cache_key] = 'test-package'

      described_class.parse_package_registry_operations(line, timestamp, current_cache, events)

      expect(events.size).to eq(1)
      expect(events.first[:cache_result]).to eq('miss')
    end

    it 'handles package downloaded pattern' do
      line = "Archive downloaded successfully"
      current_cache[:cache_key] = 'test-package'
      current_cache[:cache_result] = 'hit'
      current_cache[:started_at] = timestamp - 10

      described_class.parse_package_registry_operations(line, timestamp, current_cache, events)

      expect(events.size).to eq(1)
      expect(events.first[:cache_key]).to eq('test-package')
    end

    it 'handles package uploaded pattern' do
      events << {
        cache_operation: 'push',
        cache_type: 'assets-package',
        cache_result: 'creating',
        started_at: timestamp - 30
      }
      line = "Assets package uploaded successfully"

      described_class.parse_package_registry_operations(line, timestamp, current_cache, events)

      expect(events.first[:cache_result]).to eq('created')
      expect(events.first[:duration]).to eq(30.0)
    end
  end

  describe '.handle_downloading_package' do
    it 'sets cache result to hit when cache key exists' do
      current_cache = { cache_key: 'test-package' }
      described_class.handle_downloading_package(current_cache)

      expect(current_cache[:cache_result]).to eq('hit')
      expect(current_cache[:cache_size_bytes]).to be_nil
    end

    it 'returns early when no cache key' do
      current_cache = {}
      result = described_class.handle_downloading_package(current_cache)

      expect(result).to be_nil
      expect(current_cache[:cache_result]).to be_nil
    end
  end

  describe '.handle_package_downloaded' do
    let(:timestamp) { Time.now }
    let(:events) { [] }

    it 'processes successful package download' do
      current_cache = {
        cache_key: 'test-package',
        cache_result: 'hit',
        started_at: timestamp - 10
      }

      described_class.handle_package_downloaded(timestamp, current_cache, events)

      expect(events.size).to eq(1)
      expect(events.first[:cache_key]).to eq('test-package')
      expect(current_cache).to be_empty
    end

    it 'returns early when no cache key' do
      current_cache = {}

      result = described_class.handle_package_downloaded(timestamp, current_cache, events)

      expect(result).to be_nil
      expect(events).to be_empty
    end

    it 'returns early when cache result is not hit' do
      current_cache = { cache_key: 'test', cache_result: 'miss' }

      result = described_class.handle_package_downloaded(timestamp, current_cache, events)

      expect(result).to be_nil
      expect(events).to be_empty
    end
  end

  describe '.handle_uploading_package' do
    let(:timestamp) { Time.now }
    let(:events) { [] }

    it 'creates package upload event' do
      described_class.handle_uploading_package(timestamp, events)

      expect(events.size).to eq(1)
      event = events.first
      expect(event[:cache_key]).to eq('assets-package-upload')
      expect(event[:cache_type]).to eq('assets-package')
      expect(event[:cache_operation]).to eq('push')
      expect(event[:cache_result]).to eq('creating')
      expect(event[:started_at]).to eq(timestamp)
    end
  end

  describe '.handle_package_uploaded' do
    let(:timestamp) { Time.now }
    let(:start_time) { timestamp - 60 }

    it 'completes package upload event' do
      events = [{
        cache_operation: 'push',
        cache_type: 'assets-package',
        cache_result: 'creating',
        started_at: start_time
      }]

      described_class.handle_package_uploaded(timestamp, events)

      upload_event = events.first
      expect(upload_event[:cache_result]).to eq('created')
      expect(upload_event[:duration]).to eq(60.0)
      expect(upload_event[:cache_size_bytes]).to be_nil
    end

    it 'returns early when no upload event found' do
      events = []

      result = described_class.handle_package_uploaded(timestamp, events)

      expect(result).to be_nil
    end

    it 'returns early when no matching upload event' do
      events = [{
        cache_operation: 'pull', # Different operation
        cache_type: 'assets-package'
      }]

      result = described_class.handle_package_uploaded(timestamp, events)

      expect(result).to be_nil
    end
  end

  describe '.infer_cache_type' do
    it 'identifies ruby-gems cache' do
      result = described_class.infer_cache_type('ruby-gems-debian-bookworm-ruby-3.3.8')
      expect(result).to eq('ruby-gems')
    end

    it 'identifies node-modules cache' do
      result = described_class.infer_cache_type('node-modules-debian-bookworm-production-22')
      expect(result).to eq('node-modules')
    end

    it 'identifies go cache from go-pkg' do
      result = described_class.infer_cache_type('go-pkg-debian-bookworm-22')
      expect(result).to eq('go')
    end

    it 'identifies go cache from gitaly' do
      result = described_class.infer_cache_type('gitaly-binaries-debian-bookworm-22')
      expect(result).to eq('go')
    end

    it 'identifies assets-package cache' do
      result = described_class.infer_cache_type('assets-package-425ea29327e8')
      expect(result).to eq('assets-package')
    end

    it 'identifies regular assets cache' do
      result = described_class.infer_cache_type('assets-tmp-debian-bookworm-ruby-3.3.8')
      expect(result).to eq('assets')
    end

    it 'identifies rubocop cache' do
      result = described_class.infer_cache_type('rubocop-debian-bookworm-ruby-3.3.8')
      expect(result).to eq('rubocop')
    end

    it 'identifies qa-ruby-gems cache' do
      result = described_class.infer_cache_type('qa-ruby-gems-debian-bookworm-ruby-3.3.8')
      expect(result).to eq('ruby-gems')
    end

    it 'identifies qa-ruby-gems cache from qa-ruby pattern' do
      result = described_class.infer_cache_type('qa-ruby-test-cache')
      expect(result).to eq('qa-ruby-gems')
    end

    it 'identifies helm cache' do
      result = described_class.infer_cache_type('cng-helm-cache-ref')
      expect(result).to eq('cng-helm')
    end

    it 'returns unknown for unrecognized patterns' do
      result = described_class.infer_cache_type('unknown-cache-type')
      expect(result).to eq('unknown')
    end
  end

  describe '.infer_operation_command' do
    it 'infers bundle install for ruby-gems' do
      result = described_class.infer_operation_command('ruby-gems-test', 'ruby-gems')
      expect(result).to eq('bundle install')
    end

    it 'infers yarn install for node-modules' do
      result = described_class.infer_operation_command('node-modules-test', 'node-modules')
      expect(result).to eq('yarn install')
    end

    it 'infers assets compilation for assets' do
      result = described_class.infer_operation_command('assets-test', 'assets')
      expect(result).to eq('assets compilation')
    end

    it 'infers rubocop analysis for rubocop' do
      result = described_class.infer_operation_command('rubocop-test', 'rubocop')
      expect(result).to eq('rubocop analysis')
    end

    it 'infers from cache key when cache type not provided' do
      result = described_class.infer_operation_command('ruby-gems-test')
      expect(result).to eq('bundle install')
    end

    it 'returns nil for unknown cache types' do
      result = described_class.infer_operation_command('unknown-test', 'unknown')
      expect(result).to be_nil
    end
  end

  describe '.extract_timestamp' do
    it 'extracts valid timestamp' do
      line = '2025-07-24T14:11:26.953582Z Some log message'
      result = described_class.extract_timestamp(line)

      expect(result).to be_a(Time)
      expect(result.year).to eq(2025)
      expect(result.month).to eq(7)
      expect(result.day).to eq(24)
    end

    it 'returns nil for invalid timestamp' do
      line = 'Log message without timestamp'
      result = described_class.extract_timestamp(line)

      expect(result).to be_nil
    end

    it 'handles malformed timestamps gracefully' do
      line = '2025-13-99T25:99:99Z Invalid timestamp'
      result = described_class.extract_timestamp(line)

      expect(result).to be_nil
    end
  end

  describe '.calculate_duration' do
    let(:start_time) { Time.parse('2025-07-24T14:11:26.953582Z') }
    let(:end_time) { Time.parse('2025-07-24T14:11:35.382214Z') }

    it 'calculates duration between timestamps' do
      result = described_class.calculate_duration(start_time, end_time)
      expect(result).to be_within(0.1).of(8.4)
    end

    it 'rounds duration to 2 decimal places' do
      result = described_class.calculate_duration(start_time, end_time)
      expect(result.to_s.split('.').last.length).to be <= 2
    end

    it 'returns nil when start_time is nil' do
      result = described_class.calculate_duration(nil, end_time)
      expect(result).to be_nil
    end

    it 'returns nil when end_time is nil' do
      result = described_class.calculate_duration(start_time, nil)
      expect(result).to be_nil
    end

    it 'returns nil when both times are nil' do
      result = described_class.calculate_duration(nil, nil)
      expect(result).to be_nil
    end
  end

  describe '.extract_cache_size' do
    it 'extracts size in bytes' do
      line = 'Cache downloaded: 1024 bytes'
      expect(described_class.extract_cache_size(line)).to eq(1024)
    end

    it 'extracts size in KB' do
      line = 'Cache downloaded: 5.5 KB'
      expect(described_class.extract_cache_size(line)).to eq(5632)
    end

    it 'extracts size in MB' do
      line = 'Cache downloaded: 2.5 MB'
      expect(described_class.extract_cache_size(line)).to eq(2621440)
    end

    it 'returns nil for unrecognized format' do
      line = 'No size information here'
      expect(described_class.extract_cache_size(line)).to be_nil
    end
  end

  describe '.extract_package_size' do
    it 'extracts size in bytes' do
      line = "Package size: 1024 bytes"
      expect(described_class.extract_package_size(line)).to eq(1024)
    end

    it 'extracts size in KB' do
      line = "Package size: 5.2 KB"
      expect(described_class.extract_package_size(line)).to eq(5324)
    end

    it 'extracts size in MB' do
      line = "Package size: 10.5 MB"
      expect(described_class.extract_package_size(line)).to eq(11010048)
    end

    it 'returns nil for unrecognized format' do
      line = "No size information here"
      expect(described_class.extract_package_size(line)).to be_nil
    end
  end

  describe '.extract_size_from_line' do
    it 'handles else case in unit conversion' do
      line = 'Size: 5.5 XB' # Invalid unit
      pattern = /(\d+(?:\.\d+)?)\s*([KMX])B/i

      result = described_class.extract_size_from_line(line, pattern)

      expect(result).to eq(5) # Falls through to else case
    end
  end

  describe 'integration scenarios' do
    context 'with real GitLab CI log' do
      let(:real_log_content) do
        <<~LOG
          2025-07-24T14:11:26.953582Z Checking cache for ruby-gems-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
          2025-07-24T14:11:35.382214Z Successfully extracted cache
          2025-07-24T14:11:35.403598Z Checking cache for rubocop-debian-bookworm-ruby-3.3.8-gemfile-Gemfile-22...
          2025-07-24T14:11:38.662550Z Downloading cache from https://storage.googleapis.com/...
          2025-07-24T14:11:38.662550Z Successfully extracted cache
          2025-07-24T14:11:46.639408Z Installing gems
          2025-07-24T14:11:50.334110Z Bundle complete!
          2025-07-24T14:11:50.639408Z Installing Yarn packages
          2025-07-24T14:11:52.334110Z Done in 1.7s.
        LOG
      end

      it 'processes complex real-world logs correctly' do
        events = described_class.extract_cache_events(real_log_content)

        expect(events.size).to eq(2)

        ruby_event = events.find { |e| e[:cache_type] == 'ruby-gems' }
        expect(ruby_event[:cache_result]).to eq('hit')
        expect(ruby_event[:operation_command]).to eq('bundle install')
        expect(ruby_event[:operation_success]).to be(true)

        rubocop_event = events.find { |e| e[:cache_type] == 'rubocop' }
        expect(rubocop_event[:cache_result]).to eq('hit')
      end
    end

    context 'with cache creation scenario' do
      let(:cache_creation_log) do
        <<~LOG
          2025-07-24T14:11:26.953582Z WARNING: go-pkg-debian-bookworm-22: not found
          2025-07-24T14:11:27.953582Z Installing Go dependencies...
          2025-07-24T14:13:30.953582Z Creating cache go-pkg-debian-bookworm-22...
          2025-07-24T14:15:45.953582Z Created cache
        LOG
      end

      it 'handles cache miss followed by creation' do
        events = described_class.extract_cache_events(cache_creation_log)

        expect(events.size).to eq(1)
        event = events.first
        expect(event[:cache_key]).to eq('go-pkg-debian-bookworm-22')
        expect(event[:cache_type]).to eq('go')
        expect(event[:cache_operation]).to eq('push')
        expect(event[:cache_result]).to eq('created')
        expect(event[:duration]).to be_within(1).of(135)
      end
    end
  end
end
