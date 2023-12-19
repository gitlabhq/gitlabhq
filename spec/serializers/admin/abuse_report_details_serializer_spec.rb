# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportDetailsSerializer, feature_category: :insider_threat do
  let_it_be(:resource) { build_stubbed(:abuse_report) }

  subject { described_class.new.represent(resource).keys }

  describe '#represent' do
    it 'serializes an abuse report' do
      is_expected.to match_array([
        :user,
        :report,
        :upload_note_attachment_path
      ])
    end
  end
end
