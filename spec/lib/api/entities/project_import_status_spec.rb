# frozen_string_literal: true

require 'spec_helper'

describe API::Entities::ProjectImportStatus do
  describe '#as_json' do
    subject { entity.as_json }

    let(:correlation_id) { 'cid' }

    context 'when import has not finished yet' do
      let(:project) { create(:project, :import_scheduled, import_correlation_id: correlation_id) }
      let(:entity) { described_class.new(project) }

      it 'includes basic fields and no failures', :aggregate_failures do
        expect(subject[:import_status]).to eq('scheduled')
        expect(subject[:correlation_id]).to eq(correlation_id)
        expect(subject[:import_error]).to be_nil
        expect(subject[:failed_relations]).to eq([])
      end
    end

    context 'when import has finished with failed relations' do
      let(:project) { create(:project, :import_finished, import_correlation_id: correlation_id) }
      let(:entity) { described_class.new(project) }

      it 'includes basic fields with failed relations', :aggregate_failures do
        create(:import_failure, :hard_failure, project: project, correlation_id_value: correlation_id)

        expect(subject[:import_status]).to eq('finished')
        expect(subject[:correlation_id]).to eq(correlation_id)
        expect(subject[:import_error]).to be_nil
        expect(subject[:failed_relations]).not_to be_empty
      end
    end

    context 'when import has failed' do
      let(:project) { create(:project, :import_failed, import_correlation_id: correlation_id, import_last_error: 'error') }
      let(:entity) { described_class.new(project) }

      it 'includes basic fields with import error', :aggregate_failures do
        expect(subject[:import_status]).to eq('failed')
        expect(subject[:correlation_id]).to eq(correlation_id)
        expect(subject[:import_error]).to eq('error')
        expect(subject[:failed_relations]).to eq([])
      end
    end
  end
end
