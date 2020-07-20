# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportIssuesCsvWorker do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:upload) { create(:upload) }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'calls #execute on Issues::ImportCsvService and destroys upload' do
      expect_next_instance_of(Issues::ImportCsvService) do |instance|
        expect(instance).to receive(:execute).and_return({ success: 5, errors: [], valid_file: true })
      end

      worker.perform(user.id, project.id, upload.id)

      expect { upload.reload }.to raise_error ActiveRecord::RecordNotFound
    end
  end
end
