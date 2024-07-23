# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::TypePolicy, feature_category: :team_planning do
  let(:user) { build_stubbed(:user) }

  subject(:policy) { described_class.new(user, work_item_type) }

  context 'when work item type is present' do
    let(:work_item_type) { build_stubbed(:work_item_type) }

    it { is_expected.to be_allowed(:read_work_item_type) }
  end

  context 'when work item type is not present' do
    let(:work_item_type) { nil }

    it { is_expected.to be_disallowed(:read_work_item_type) }
  end
end
