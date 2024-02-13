# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Designs, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }

  describe '.type' do
    specify { expect(described_class.type).to eq(:designs) }
  end

  describe '#type' do
    specify { expect(described_class.new(work_item).type).to eq(:designs) }
  end

  describe '#designs' do
    it 'returns all designs' do
      create_list(:design, 3, :with_file, issue: work_item)
      design_a = create(:design, :with_file, issue: work_item)

      expect(described_class.new(work_item).designs.count).to eq(4)

      expect(described_class.new(work_item).designs).to include(design_a)
    end
  end

  describe '#design_versions' do
    it 'returns all design versions' do
      create_list(:design_version, 2, issue: work_item)
      last_version = create(:design_version, issue: work_item)

      expect(described_class.new(work_item).design_versions.count).to eq(3)
      expect(described_class.new(work_item).design_versions).to include(last_version)
    end
  end

  describe '#design_collection' do
    it 'returns a design collection' do
      collection = described_class.new(work_item).design_collection

      expect(collection).to be_a(DesignManagement::DesignCollection)
      expect(collection.issue).to eq(work_item)
    end
  end
end
