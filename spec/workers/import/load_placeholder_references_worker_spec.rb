# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::LoadPlaceholderReferencesWorker, feature_category: :importers do
  let(:user) { create(:user) }
  let(:import_source) { 'test_source' }
  let(:uid) { 123 }
  let(:params) { { 'current_user_id' => user.id } }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(import_source, uid, params) }

    it 'executes LoadService' do
      expect_next_instance_of(Import::PlaceholderReferences::LoadService) do |service|
        expect(service).to receive(:execute)
      end

      perform
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [import_source, uid, params] }
    end

    context 'when importer_user_mapping feature is disabled' do
      before do
        stub_feature_flags(importer_user_mapping: false)
      end

      it 'does not execute LoadService' do
        expect(Import::PlaceholderReferences::LoadService).not_to receive(:new)

        perform
      end

      context 'when importer_user_mapping feature is enabled for the user' do
        before do
          stub_feature_flags(importer_user_mapping: user)
        end

        it 'executes LoadService' do
          expect_next_instance_of(Import::PlaceholderReferences::LoadService) do |service|
            expect(service).to receive(:execute)
          end

          perform
        end
      end
    end
  end
end
