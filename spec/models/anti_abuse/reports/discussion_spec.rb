# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Reports::Discussion, feature_category: :insider_threat do
  describe '.base_discussion_id' do
    it 'returns the correct value' do
      expect(described_class.base_discussion_id(nil)).to eq([:discussion, :abuse_report_id])
    end
  end

  describe '.note_class' do
    it 'returns the correct value' do
      expect(described_class.note_class).to eq(AntiAbuse::Reports::DiscussionNote)
    end
  end
end
