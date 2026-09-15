# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::QueryLogs, feature_category: :database do
  describe '.tags' do
    it 'annotates the queries with the expected keys' do
      keys = described_class.tags.flat_map(&:keys)

      expect(keys).to start_with(
        :application, :correlation_id, :jid, :endpoint_id, :db_config_database, :db_config_name,
        :console_hostname, :console_username
      )
    end

    it 'resolves the application name eagerly' do
      expect(described_class.tags.first).to eq({ application: Gitlab.process_name })
    end

    context 'when the source location is enabled' do
      before do
        allow(described_class).to receive(:line_enabled?).and_return(true)
      end

      it 'includes the source location tag' do
        expect(described_class.tags).to include(described_class::LINE_TAG)
      end
    end

    context 'when the source location is disabled' do
      before do
        allow(described_class).to receive(:line_enabled?).and_return(false)
      end

      it 'excludes the source location tag' do
        expect(described_class.tags).not_to include(described_class::LINE_TAG)
      end
    end

    # The handlers are captured once at boot, but in development Zeitwerk
    # replaces this module tree on code reload. Stale handlers must resolve
    # the freshly loaded module, not the unloaded one they were defined in.
    it 'resolves the tag module at call time so handlers survive code reloading' do
      allow(described_class).to receive(:line_enabled?).and_return(true)

      handlers = described_class.tags.drop(1).reduce({}, :merge)
      fresh_tags = Module.new
      handlers.each_key { |key| fresh_tags.define_singleton_method(key) { |_context| key } }
      fresh_query_logs = Module.new
      fresh_query_logs.const_set(:Tags, fresh_tags)

      stub_const('Gitlab::QueryLogs', fresh_query_logs)

      expect(handlers.map { |_key, handler| handler.call(nil) }).to eq(handlers.keys)
    end
  end

  describe '.line_enabled?' do
    where(:dev_or_test_env, :ci, :env_var, :expected) do
      [
        [false, nil,    nil,      false],
        [false, 'true', 'true',   false],
        [true,  nil,    nil,      true],
        [true,  nil,    'false',  false],
        [true,  'true', nil,      false],
        [true,  'true', 'true',   true]
      ]
    end

    with_them do
      before do
        allow(Gitlab).to receive(:dev_or_test_env?).and_return(dev_or_test_env)
        stub_env('CI', ci)
        stub_env('QUERY_LOG_LINE', env_var)
      end

      it { expect(described_class.line_enabled?).to eq(expected) }
    end
  end
end
