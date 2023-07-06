# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::BatchedBackgroundMigrationsMetric, feature_category: :database do
  let(:expected_value) do
    [
      {
        job_class_name: 'test',
        elapsed_time: 2.days.to_i
      }
    ]
  end

  let_it_be(:active_migration) { create(:batched_background_migration, :active) }
  let_it_be(:finished_migration) do
    create(:batched_background_migration, :finished, job_class_name: 'test', started_at: 5.days.ago,
      finished_at: 3.days.ago)
  end

  let_it_be(:old_finished_migration) do
    create(:batched_background_migration, :finished, job_class_name: 'old_test', started_at: 100.days.ago,
      finished_at: 99.days.ago)
  end

  it_behaves_like 'a correct instrumented metric value', { time_frame: '7d' }
end
