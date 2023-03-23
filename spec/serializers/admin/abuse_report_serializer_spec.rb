# frozen_string_literal: true

require "spec_helper"

RSpec.describe Admin::AbuseReportSerializer, feature_category: :insider_threat do
  let_it_be(:resource) { build_stubbed(:abuse_report) }

  subject { described_class.new.represent(resource) }

  describe '#represent' do
    it 'serializes an abuse report' do
      expect(subject[:updated_at]).to eq resource.updated_at
    end

    context 'when multiple objects are being serialized' do
      let_it_be(:resource) { create_list(:abuse_report, 2) } # rubocop:disable RSpec/FactoryBot/AvoidCreate

      it 'serializers the array of abuse reports' do
        expect(subject).not_to be_empty
      end
    end
  end
end
