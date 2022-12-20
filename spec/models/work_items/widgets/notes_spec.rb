# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Notes, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:note) { create(:note, noteable: work_item, project: work_item.project) }

  describe '.type' do
    it { expect(described_class.type).to eq(:notes) }
  end

  describe '#type' do
    it { expect(described_class.new(work_item).type).to eq(:notes) }
  end

  describe '#notes' do
    it { expect(described_class.new(work_item).notes).to eq(work_item.notes) }
  end
end
