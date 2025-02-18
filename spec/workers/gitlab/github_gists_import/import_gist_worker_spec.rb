# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubGistsImport::ImportGistWorker, feature_category: :importers do
  subject { described_class.new }

  let_it_be(:organization) { create(:organization) }
  let_it_be(:user) { create(:user, organizations: [organization]) }

  let(:token) { 'token' }
  let(:gist_hash) do
    {
      id: '055b70',
      git_pull_url: 'https://gist.github.com/foo/bar.git',
      files: {
        'random.txt': {
          filename: 'random.txt',
          type: 'text/plain',
          language: 'Text',
          raw_url: 'https://gist.githubusercontent.com/user_name/055b70/raw/66a7be0d/random.txt',
          size: 166903
        }
      },
      is_public: false,
      created_at: '2022-09-06T11:38:18Z',
      updated_at: '2022-09-06T11:38:18Z',
      description: 'random text'
    }
  end

  let(:importer) { instance_double('Gitlab::GithubGistsImport::Importer::GistImporter') }
  let(:importer_result) { instance_double('ServiceResponse', success?: true) }
  let(:gist_object) do
    instance_double('Gitlab::GithubGistsImport::Representation::Gist',
      gist_hash.merge(github_identifiers: { id: '055b70' }, truncated_title: 'random text', visibility_level: 0))
  end

  let(:log_attributes) do
    {
      'user_id' => user.id,
      'external_identifiers' => { id: gist_object.id },
      'class' => 'Gitlab::GithubGistsImport::ImportGistWorker',
      'correlation_id' => 'new-correlation-id',
      'jid' => nil,
      'job_status' => 'running',
      'queue' => 'github_gists_importer:github_gists_import_import_gist'
    }
  end

  describe '#perform' do
    before do
      allow(Gitlab::GithubGistsImport::Representation::Gist)
        .to receive(:from_json_hash)
        .with(gist_hash)
        .and_return(gist_object)

      allow(Gitlab::GithubGistsImport::Importer::GistImporter)
        .to receive(:new)
        .with(gist_object, user.id)
        .and_return(importer)

      allow(Gitlab::ApplicationContext).to receive(:current).and_return('correlation_id' => 'new-correlation-id')
      allow(described_class).to receive(:queue).and_return('github_gists_importer:github_gists_import_import_gist')
    end

    context 'when success' do
      it 'imports gist' do
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'start importer'))
        expect(importer).to receive(:execute).and_return(importer_result)
        expect(Gitlab::JobWaiter).to receive(:notify).with('some_key', subject.jid, ttl: Gitlab::Import::JOB_WAITER_TTL)
        expect(Gitlab::GithubImport::Logger)
          .to receive(:info)
          .with(log_attributes.merge('message' => 'importer finished'))

        subject.perform(user.id, gist_hash, 'some_key')

        expect_snowplow_event(
          category: 'Gitlab::GithubGistsImport::ImportGistWorker',
          label: 'github_gist_import',
          action: 'create',
          user: user,
          status: 'success'
        )
      end
    end

    context 'when failure' do
      context 'when importer raised an error' do
        let(:exception) { StandardError.new('_some_error_') }

        before do
          allow(importer).to receive(:execute).and_raise(exception)
        end

        it 'raises an error' do
          expect(Gitlab::GithubImport::Logger)
            .to receive(:error)
            .with(log_attributes.merge('message' => 'importer failed', 'exception.message' => '_some_error_'))
          expect(Gitlab::ErrorTracking).to receive(:track_exception)

          expect { subject.perform(user.id, gist_hash, 'some_key') }.to raise_error(StandardError)
        end
      end

      context 'when importer returns error' do
        let(:importer_result) { instance_double('ServiceResponse', errors: 'error_message', success?: false) }

        before do
          allow(importer).to receive(:execute).and_return(importer_result)
          allow(Gitlab::GithubGistsImport::Representation::Gist)
            .to receive(:from_json_hash)
            .with(anything)
            .and_return(gist_object)
        end

        it 'tracks and logs error' do
          # use `anything` since jid is created in Sidekiq's middleware. `jid` does not exist until
          # perform_inline is called.
          expect(Gitlab::GithubImport::Logger)
            .to receive(:error)
            .with(log_attributes.merge('message' => 'importer failed', 'exception.message' => 'error_message',
              'jid' => anything))
          expect(Gitlab::JobWaiter)
            .to receive(:notify)
            .with('some_key', anything, ttl: Gitlab::Import::JOB_WAITER_TTL)

          subject.class.perform_inline(user.id, gist_hash, 'some_key') # perform_inline calls .perform

          expect_snowplow_event(
            category: 'Gitlab::GithubGistsImport::ImportGistWorker',
            label: 'github_gist_import',
            action: 'create',
            user: user,
            status: 'failed'
          )
        end

        it 'persists failure' do
          expect { subject.class.perform_inline(user.id, gist_hash, 'some_key') }
            .to change { ImportFailure.where(user: user).count }.from(0).to(1)

          expect(ImportFailure.where(user_id: user.id).first).to have_attributes(
            source: 'Gitlab::GithubGistsImport::Importer::GistImporter',
            exception_class: 'Gitlab::GithubGistsImport::Importer::GistImporter::FileCountLimitError',
            exception_message: 'Snippet maximum file count exceeded',
            external_identifiers: {
              'id' => '055b70'
            }
          )
        end
      end
    end

    describe '.sidekiq_retries_exhausted' do
      subject(:sidekiq_retries_exhausted) do
        described_class.sidekiq_retries_exhausted_block.call(job, StandardError.new)
      end

      let(:args) { [user.id, gist_hash, '1'] }

      let(:job) do
        {
          'args' => args,
          'jid' => '123',
          'correlation_id' => 'abc',
          'error_class' => 'StandardError',
          'error_message' => 'Some error'
        }
      end

      it 'persists failure' do
        expect { sidekiq_retries_exhausted }.to change { ImportFailure.where(user: user).count }.from(0).to(1)

        expect(ImportFailure.where(user_id: user.id).first).to have_attributes(
          source: 'Gitlab::GithubGistsImport::Importer::GistImporter',
          exception_class: 'StandardError',
          exception_message: 'Some error',
          correlation_id_value: 'abc',
          external_identifiers: {
            'id' => '055b70'
          }
        )
      end

      it 'sends snowplow event' do
        sidekiq_retries_exhausted

        expect_snowplow_event(
          category: 'Gitlab::GithubGistsImport::ImportGistWorker',
          label: 'github_gist_import',
          action: 'create',
          user: user,
          status: 'failed'
        )
      end

      it 'notifies the JobWaiter' do
        expect(Gitlab::JobWaiter)
          .to receive(:notify)
          .with(job['args'].last, job['jid'], ttl: Gitlab::Import::JOB_WAITER_TTL)

        sidekiq_retries_exhausted
      end

      context 'when not all arguments are given' do
        let(:args) { [user.id, gist_hash] }

        it 'does not notify the JobWaiter' do
          expect(Gitlab::JobWaiter).not_to receive(:notify)

          sidekiq_retries_exhausted
        end
      end
    end
  end
end
