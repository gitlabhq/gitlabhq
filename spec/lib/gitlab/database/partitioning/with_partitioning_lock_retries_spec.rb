# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::WithPartitioningLockRetries, feature_category: :database do
  let(:connection) { ActiveRecord::Base.retrieve_connection }
  let(:logger) { instance_spy(Gitlab::JsonLogger) }

  # takes the shortest path to a log line, so the block runs once and logs once
  let(:env) { { 'DISABLE_LOCK_RETRIES' => 'true' } }

  subject(:retries) do
    described_class.new(connection: connection, logger: logger, env: env, klass: described_class, **options)
  end

  before do
    retries.run { nil }
  end

  context 'without extra log params' do
    let(:options) { {} }

    it 'logs the caller class' do
      expect(logger).to have_received(:info).with(
        hash_including('class_name' => described_class.to_s)
      )
    end
  end

  context 'with extra log params' do
    let(:options) { { extra_log_params: { table_name: 'p_ci_builds' } } }

    it 'logs them alongside the caller class' do
      expect(logger).to have_received(:info).with(
        hash_including('class_name' => described_class.to_s, 'table_name' => 'p_ci_builds')
      )
    end
  end
end
