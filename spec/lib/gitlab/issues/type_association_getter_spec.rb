# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Issues::TypeAssociationGetter, feature_category: :team_planning do
  describe '.call' do
    subject { described_class.call }

    it { is_expected.to eq(:correct_work_item_type) }
  end
end
