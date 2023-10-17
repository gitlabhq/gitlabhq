# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::StartImportWorker, feature_category: :importers do
  subject(:worker) { described_class.new }

  let_it_be(:user) { create(:user) }
  let(:token) { Gitlab::CryptoHelper.aes256_gcm_encrypt('token') }
  let(:importer) { instance_double(Gitlab::GithubGistsImport::Importer::GistsImporter) }
  let(:waiter) { instance_double(Gitlab::JobWaiter, key: :key, jobs_remaining: 1) }
  let(:importer_context) { Struct.new(:success?, :error, :waiter, :next_attempt_in, keyword_init: true) }
  let(:log_attributes) do
    {
      'user_id' => user.id,
      'class' => described_class.name,
      'correlation_id' => 'new-correlation-id',
      'jid' => nil,
      'job_status' => 'running',
      'queue' => 'github_gists_importer:github_gists_import_start_import'
    }
  end

  describe '#perform', :aggregate_failures do
    before do
      allow(Gitlab::GithubImport::Logger)
        .to receive(:info)
        .with(log_attributes.merge('message' => 'starting importer'))

      allow(Gitlab::ApplicationContext).to receive(:current).and_return('correlation_id' => 'new-correlation-id')
      allow(described_class).to receive(:queue).and_return('github_gists_importer:github_gists_import_start_import')
    end

    context 'when import was successfull' do
      it 'imports all the gists' do
        expect(Gitlab::CryptoHelper)
          .to receive(:aes256_gcm_decrypt)
          .with(token)
          .and_call_original

        expect(Gitlab::GithubGistsImport::Importer::GistsImporter)
          .to receive(:new)
          .with(user, 'token')
          .and_return(importer)

        expect(importer)
          .to receive(:execute)
          .and_return(importer_context.new(success?: true, waiter: waiter))

        expect(Gitlab::GithubGistsImport::FinishImportWorker)
          .to receive(:perform_async)
          .with(user.id, waiter.key, waiter.jobs_remaining)

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'importer finished'))

        worker.perform(user.id, token)
      end
    end

    context 'when importer returns an error' do
      it 'raises an error' do
        exception = StandardError.new('_some_error_')
        importer_result = importer_context.new(success?: false, error: exception)

        expect_next_instance_of(Gitlab::GithubGistsImport::Importer::GistsImporter) do |importer|
          expect(importer).to receive(:execute).and_return(importer_result)
        end

        expect(Gitlab::GithubImport::Logger)
          .to receive(:error)
          .with(log_attributes.merge('message' => 'import failed', 'exception.message' => exception.message))

        expect { worker.perform(user.id, token) }.to raise_error(StandardError)
      end
    end

    context 'when rate limit is reached' do
      it 'reschedules worker' do
        exception = Gitlab::GithubImport::RateLimitError.new
        importer_result = importer_context.new(success?: false, error: exception, next_attempt_in: 5)

        expect_next_instance_of(Gitlab::GithubGistsImport::Importer::GistsImporter) do |importer|
          expect(importer).to receive(:execute).and_return(importer_result)
        end

        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'rate limit reached'))

        expect(described_class).to receive(:perform_in).with(5, user.id, token)

        worker.perform(user.id, token)
      end
    end
  end

  describe '.sidekiq_retries_exhausted' do
    it 'sets status to failed' do
      job = { 'args' => [user.id, token], 'jid' => '123' }

      expect_next_instance_of(Gitlab::GithubGistsImport::Status) do |status|
        expect(status).to receive(:fail!)
      end

      described_class.sidekiq_retries_exhausted_block.call(job)
    end
  end
end
