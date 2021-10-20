# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::CountUsersAssociatingMilestonesToReleasesMetric do
  let_it_be(:release) { create(:release, created_at: 3.days.ago) }
  let_it_be(:release_with_milestone) { create(:release, :with_milestones, created_at: 3.days.ago) }

  it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', data_source: 'database' } do
    let(:expected_value) { 1 }
  end
end
