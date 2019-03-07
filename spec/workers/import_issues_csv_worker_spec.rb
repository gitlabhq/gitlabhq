# frozen_string_literal: true

require 'spec_helper'

describe ImportIssuesCsvWorker do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:upload) { create(:upload) }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'calls #execute on Issues::ImportCsvService and destroys upload' do
      expect_any_instance_of(Issues::ImportCsvService).to receive(:execute).and_return({ success: 5, errors: [], valid_file: true })

      worker.perform(user.id, project.id, upload.id)

      expect { upload.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
