# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::ImportWorkItemsCsvWorker, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, reporter_of: project) }

  let(:upload) { create(:upload, :with_file) }

  subject { described_class.new.perform(user.id, project.id, upload.id) }

  describe '#perform' do
    it 'calls #execute on WorkItems::ImportCsvService and destroys upload' do
      expect_next_instance_of(WorkItems::ImportCsvService) do |instance|
        expect(instance).to receive(:execute).and_return({ success: 5, error_lines: [], parse_error: false })
      end

      subject

      expect { upload.reload }.to raise_error ActiveRecord::RecordNotFound
    end

    it_behaves_like 'an idempotent worker' do
      let(:job_args) { [user.id, project.id, upload.id] }
    end
  end

  describe '.sidekiq_retries_exhausted' do
    let_it_be(:job) { { 'args' => [user.id, project.id, create(:upload, :with_file).id] } }

    subject(:sidekiq_retries_exhausted) do
      described_class.sidekiq_retries_exhausted_block.call(job)
    end

    it 'destroys upload' do
      expect { sidekiq_retries_exhausted }.to change { Upload.count }.by(-1)
    end
  end
end
