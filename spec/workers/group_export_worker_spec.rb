# frozen_string_literal: true

require 'spec_helper'

describe GroupExportWorker do
  let!(:user) { create(:user) }
  let!(:group) { create(:group) }

  subject { described_class.new }

  describe '#perform' do
    context 'when it succeeds' do
      it 'calls the ExportService' do
        expect_any_instance_of(::Groups::ImportExport::ExportService).to receive(:execute)

        subject.perform(user.id, group.id, {})
      end
    end

    context 'when it fails' do
      it 'raises an exception when params are invalid' do
        expect_any_instance_of(::Groups::ImportExport::ExportService).not_to receive(:execute)

        expect { subject.perform(1234, group.id, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
        expect { subject.perform(user.id, 1234, {}) }.to raise_exception(ActiveRecord::RecordNotFound)
      end
    end
  end
end
