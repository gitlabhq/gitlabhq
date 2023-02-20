# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::Observers::BatchDetails, feature_category: :database do
  subject(:observe) { described_class.new(observation, path, connection) }

  let(:connection) { ActiveRecord::Migration.connection }
  let(:observation) { Gitlab::Database::Migrations::Observation.new(meta: meta) }
  let(:path) { Dir.mktmpdir }
  let(:file_name) { 'batch-details.json' }
  let(:file_path) { Pathname.new(path).join(file_name) }
  let(:json_file) { Gitlab::Json.parse(File.read(file_path)) }
  let(:job_meta) do
    { "min_value" => 1, "max_value" => 19, "batch_size" => 20, "sub_batch_size" => 5, "pause_ms" => 100 }
  end

  where(:meta, :expected_keys) do
    [
      [lazy { { job_meta: job_meta } }, %w[time_spent min_value max_value batch_size sub_batch_size pause_ms]],
      [nil, %w[time_spent]],
      [{ job_meta: nil }, %w[time_spent]]
    ]
  end

  with_them do
    before do
      observe.before
      observe.after
    end

    after do
      FileUtils.remove_entry(path)
    end

    it 'records expected information to file' do
      observe.record

      expect(json_file.keys).to match_array(expected_keys)
    end
  end
end
