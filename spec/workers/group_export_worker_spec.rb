# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupExportWorker, feature_category: :importers do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }

  subject { described_class.new }

  describe '#perform' do
    context 'when it succeeds' do
      it 'calls the ExportService correctly' do
        expected_params = { group: group, user: user, exported_by_admin: false, params: {} }

        expect_next_instance_of(::Groups::ImportExport::ExportService, expected_params) do |service|
          expect(service).to receive(:execute)
        end

        subject.perform(user.id, group.id, { exported_by_admin: false })
      end
    end

    context 'when it fails' do
      it 'raises an exception when params are invalid' do
        expect_any_instance_of(::Groups::ImportExport::ExportService).not_to receive(:execute)

        expect { subject.perform(non_existing_record_id, group.id, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { subject.perform(user.id, non_existing_record_id, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe 'sidekiq options' do
    it 'disables retry' do
      expect(described_class.sidekiq_options['retry']).to eq(false)
    end

    it 'disables dead' do
      expect(described_class.sidekiq_options['dead']).to eq(false)
    end
  end
end
