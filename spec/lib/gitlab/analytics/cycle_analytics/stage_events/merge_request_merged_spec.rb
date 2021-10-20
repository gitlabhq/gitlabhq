# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Analytics::CycleAnalytics::StageEvents::MergeRequestMerged do
  it_behaves_like 'value stream analytics event'

  it_behaves_like 'LEFT JOIN-able value stream analytics event' do
    let_it_be(:record_with_data) { create(:merge_request).tap { |mr| mr.metrics.update!(merged_at: Time.current) } }
    let_it_be(:record_without_data) { create(:merge_request) }
  end
end
