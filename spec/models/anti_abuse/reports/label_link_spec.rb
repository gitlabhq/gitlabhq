# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AntiAbuse::Reports::LabelLink, feature_category: :insider_threat do
  subject(:instance) { build(:abuse_report_label_link) }

  it { is_expected.to be_valid }

  it { is_expected.to belong_to(:abuse_report).inverse_of(:label_links) }
  it { is_expected.to belong_to(:abuse_report_label).class_name('AntiAbuse::Reports::Label').inverse_of(:label_links) }

  describe 'validations' do
    it { is_expected.to validate_presence_of(:abuse_report) }
    it { is_expected.to validate_presence_of(:abuse_report_label) }
    it { is_expected.to validate_uniqueness_of(:abuse_report_label).scoped_to([:abuse_report_id]) }
  end
end
