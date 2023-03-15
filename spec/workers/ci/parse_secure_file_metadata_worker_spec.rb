# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::ParseSecureFileMetadataWorker, feature_category: :mobile_devops do
  describe '#perform' do
    include_examples 'an idempotent worker' do
      let(:secure_file) { create(:ci_secure_file) }
      subject { described_class.new.perform(secure_file&.id) }

      context 'when the file is found' do
        it 'calls update_metadata!' do
          allow(::Ci::SecureFile).to receive(:find_by_id).and_return(secure_file)
          expect(secure_file).to receive(:update_metadata!)

          subject
        end
      end
    end

    context 'when file is not found' do
      let(:secure_file) { nil }

      it 'does not call update_metadata!' do
        expect(secure_file).not_to receive(:update_metadata!)

        subject
      end
    end
  end
end
