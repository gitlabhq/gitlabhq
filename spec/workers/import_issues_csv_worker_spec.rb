# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportIssuesCsvWorker do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  let(:upload) { create(:upload, :with_file) }

  let(:worker) { described_class.new }

  describe '#perform' do
    it 'calls #execute on Issues::ImportCsvService and destroys upload' do
      expect_next_instance_of(Issues::ImportCsvService) do |instance|
        expect(instance).to receive(:execute).and_return({ success: 5, errors: [], valid_file: true })
      end

      worker.perform(user.id, project.id, upload.id)

      expect { upload.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, project.id, upload.id] }
    end
  end
end
