# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::Finders::Ci::FinishedBuildsFinder, :click_house, :freeze_time, feature_category: :fleet_visibility do
  include_context 'with CI job analytics test data'

  let(:instance) { described_class.new }

  it_behaves_like 'finished builds finder select behavior'
  it_behaves_like 'finished builds finder aggregations'
  it_behaves_like 'finished builds finder ordering'
  it_behaves_like 'finished builds finder offset'
  it_behaves_like 'finished builds finder grouping'
  it_behaves_like 'finished builds finder filters'
  it_behaves_like 'finished builds finder method chaining'
  it_behaves_like 'finished builds finder execution'
end
