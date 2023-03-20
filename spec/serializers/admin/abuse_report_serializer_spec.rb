# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::AbuseReportSerializer, feature_category: :insider_threat do
  let(:resource) { build(:abuse_report) }

  subject { described_class.new.represent(resource) }

  describe '#represent' do
    it 'serializes an abuse report' do
      expect(subject[:id]).to eq resource.id
    end

    context 'when multiple objects are being serialized' do
      let(:resource) { build_list(:abuse_report, 2) }

      it 'serializers the array of abuse reports' do
        expect(subject).not_to be_empty
      end
    end
  end
end
