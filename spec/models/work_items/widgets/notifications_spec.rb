# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Notifications, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }

  describe '.type' do
    it { expect(described_class.type).to eq(:notifications) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:notifications) }
  end

  describe '#subscribed?' do
    it { expect(described_class.new(work_item).subscribed?(work_item.author, work_item.project)).to eq(true) }
  end
end
