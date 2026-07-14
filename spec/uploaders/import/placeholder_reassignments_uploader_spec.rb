# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::PlaceholderReassignmentsUploader, feature_category: :importers do
  describe '.workhorse_local_upload_path' do
    it 'is provisioned under the managed uploads directory instead of public/tmp/uploads' do
      expect(described_class.workhorse_local_upload_path).to end_with('/uploads/tmp/uploads')
    end
  end

  describe '.workhorse_authorize' do
    context 'when direct upload is disabled' do
      before do
        allow(described_class).to receive(:direct_upload_to_object_store?).and_return(false)
      end

      it 'sets TempPath to the provisioned shared mount' do
        response = described_class.workhorse_authorize(has_length: false)

        expect(response[:TempPath]).to end_with('/uploads/tmp/uploads')
      end
    end
  end
end
