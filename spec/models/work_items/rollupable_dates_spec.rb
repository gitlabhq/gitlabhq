# frozen_string_literal: true

require "spec_helper"

RSpec.describe WorkItems::RollupableDates, :freeze_time, feature_category: :team_planning do
  context 'when using work item dates source' do
    let(:source) { build_stubbed(:work_items_dates_source) }

    it_behaves_like 'rollupable dates - when can_rollup is false' do
      subject(:rollupable_dates) { described_class.new(source, can_rollup: false) }
    end

    it_behaves_like 'rollupable dates - when can_rollup is true' do
      subject(:rollupable_dates) { described_class.new(source, can_rollup: true) }
    end
  end
end
