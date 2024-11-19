# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Reports::Label, feature_category: :insider_threat do
  subject(:record) { build(:abuse_report_label) }

  it_behaves_like 'BaseLabel', factory_name: :abuse_report_label

  describe 'associations' do
    it 'has many label links' do
      expect(record).to have_many(:label_links).with_foreign_key(:abuse_report_label_id).inverse_of(:abuse_report_label)
        .class_name('AntiAbuse::Reports::LabelLink')
    end

    it { is_expected.to have_many(:abuse_reports).through(:label_links) }
  end

  describe 'validation' do
    it { is_expected.to validate_uniqueness_of(:title) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
  end
end
