# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Admin::AbuseReportLabels::CreateService, feature_category: :insider_threat do
  describe '#execute' do
    let(:color) { 'red' }
    let(:color_in_hex) { ::Gitlab::Color.of(color) }
    let(:params) { { title: 'FancyLabel', color: color } }

    subject(:execute) { described_class.new(params).execute }

    shared_examples 'creates a label with the correct values' do
      it 'creates a label with the correct values', :aggregate_failures do
        expect { execute }.to change { AntiAbuse::Reports::Label.count }.from(0).to(1)

        label = AntiAbuse::Reports::Label.last
        expect(label.title).to eq params[:title]
        expect(label.color).to eq color_in_hex
      end

      it 'returns the persisted label' do
        result = execute
        expect(result).to be_an_instance_of(AntiAbuse::Reports::Label)
        expect(result.persisted?).to eq true
      end
    end

    it_behaves_like 'creates a label with the correct values'

    context 'without color param' do
      let(:params) { { title: 'FancyLabel' } }
      let(:color_in_hex) { ::Gitlab::Color.of(Label::DEFAULT_COLOR) }

      it_behaves_like 'creates a label with the correct values'
    end

    context 'with errors' do
      let!(:existing_label) { create(:abuse_report_label, title: params[:title]) }

      it 'does not create the label' do
        expect { execute }.not_to change { AntiAbuse::Reports::Label.count }
      end

      it 'returns the label with errors' do
        label = execute
        expect(label.errors.messages).to include({ title: ["has already been taken"] })
      end
    end
  end
end
