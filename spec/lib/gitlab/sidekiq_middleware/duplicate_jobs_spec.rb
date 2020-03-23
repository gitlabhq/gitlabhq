# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::SidekiqMiddleware::DuplicateJobs do
  using RSpec::Parameterized::TableSyntax

  describe '.drop_duplicates?' do
    where(:global_feature_enabled, :selected_queue_enabled, :queue, :expected) do
      true  | true  | described_class::DROPPABLE_QUEUES.first | true
      true  | true  | "other_queue"                           | true
      true  | false | described_class::DROPPABLE_QUEUES.first | true
      true  | false | "other_queue"                           | true
      false | true  | described_class::DROPPABLE_QUEUES.first | true
      false | true  | "other_queue"                           | false
      false | false | described_class::DROPPABLE_QUEUES.first | false
      false | false | "other_queue"                           | false
    end

    with_them do
      before do
        stub_feature_flags(drop_duplicate_sidekiq_jobs: global_feature_enabled,
                           drop_duplicate_sidekiq_jobs_for_queue: selected_queue_enabled)
      end

      it "allows dropping jobs when expected" do
        expect(described_class.drop_duplicates?(queue)).to be(expected)
      end
    end
  end
end
