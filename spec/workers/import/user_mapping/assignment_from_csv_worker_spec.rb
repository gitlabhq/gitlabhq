# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::UserMapping::AssignmentFromCsvWorker, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group, owners: current_user) }
  # The upload is destroyed after each run, so we can't use `let_it_be`
  let(:upload) { create(:upload, :with_file) }

  let(:job_args) { [current_user.id, group.id, upload.id] }

  subject(:perform) { described_class.new.perform(*job_args) }

  it_behaves_like 'an idempotent worker' do
    let_it_be(:user) { create(:user, :public_email, username: 'alice-gl', email: 'alice@example.com') }
    let_it_be(:source_user) do
      create(:import_source_user, :pending_reassignment, namespace: group, source_user_identifier: 'alice_1')
    end

    before do
      csv_content = <<~CSV
        Source host,Import type,Source user identifier,Source user name,Source username,GitLab username,GitLab public email
        https://github.com,github,alice_1,Alice Alison,alice,alice-gl,
      CSV

      fake_upload = build_stubbed(:upload)
      allow(fake_upload).to receive(:destroy!)
      allow(fake_upload).to receive_message_chain(:retrieve_uploader, :file, :read).and_return(csv_content)
      allow(Upload).to receive(:find_by_id).and_return(fake_upload)

      allow_next_instance_of(Import::SourceUsers::BulkReassignFromCsvService) do |service|
        allow(service).to receive(:find_source_user).and_return(source_user)
      end
    end

    it 'only tries to reassign on the user once' do
      allow(source_user).to receive(:reassign).and_call_original

      perform

      expect(source_user).to have_received(:reassign).once
    end
  end

  it 'calls the reassignment service' do
    expect(Import::SourceUsers::BulkReassignFromCsvService).to receive(:new)
      .with(current_user, group, upload)
      .and_call_original

    perform
  end

  it 'sends an email summary' # https://gitlab.com/gitlab-org/gitlab/-/issues/458841

  it 'clears the upload' do
    expect { perform }
      .to change { Upload.exists?(upload.id) }.from(true).to(false)
  end

  context 'when the service returns an error response' do
    before do
      allow(::Import::Framework::Logger).to receive(:error)

      allow_next_instance_of(Import::SourceUsers::BulkReassignFromCsvService) do |service|
        allow(service).to receive(:execute).and_return(ServiceResponse.error(message: 'something went wrong'))
      end
    end

    it 'clears the upload' do
      expect { perform }
        .to change { Upload.exists?(upload.id) }.from(true).to(false)
    end

    it 'logs the error' do
      perform

      expect(::Import::Framework::Logger)
        .to have_received(:error)
        .with(message: 'something went wrong')
    end

    it 'sends an email to notify the user of the failure' do
      expect(Notify).to receive(:csv_placeholder_reassignment_failed).with(current_user.id, group.id).and_call_original

      perform
    end
  end

  context 'when retries are exhausted' do
    it 'clears the upload' do
      job = { 'args' => job_args, 'jid' => '123' }

      expect { described_class.sidekiq_retries_exhausted_block.call(job) }
        .to change { Upload.exists?(upload.id) }.from(true).to(false)
    end

    it 'sends an email to notify the user of the failure' do
      expect(Notify).to receive(:csv_placeholder_reassignment_failed).with(current_user.id, group.id).and_call_original

      job = { 'args' => job_args, 'jid' => '123' }
      described_class.sidekiq_retries_exhausted_block.call(job)
    end
  end

  context 'when the upload is missing' do
    before do
      upload.destroy!
      allow(::Import::Framework::Logger).to receive(:error)
    end

    it 'logs' do
      perform

      expect(::Import::Framework::Logger)
        .to have_received(:error)
        .with(message: "No reassignment CSV upload found for <Group id=#{group.id}>")
    end

    it 'sends an email to notify the user of the failure' do
      expect(Notify).to receive(:csv_placeholder_reassignment_failed).with(current_user.id, group.id).and_call_original

      perform
    end
  end
end
