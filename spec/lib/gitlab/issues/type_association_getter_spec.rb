# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issues::TypeAssociationGetter, feature_category: :team_planning do
  describe '.call' do
    subject { described_class.call }

    it { is_expected.to eq(:correct_work_item_type) }

    context 'when issues_use_correct_work_item_type_id feature flag is disabled' do
      before do
        stub_feature_flags(issues_use_correct_work_item_type_id: false)
      end

      it { is_expected.to eq(:work_item_type) }
    end
  end
end
