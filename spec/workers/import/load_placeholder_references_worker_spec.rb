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

  describe '#sidekiq_retries_exhausted' do
    let_it_be(:project) { create(:project) }

    shared_examples 'failed user contribution mapping' do
      it 'logs the failure and clears the placeholder cache', :aggregate_failures do
        exception = StandardError.new('Some error')

        expect(::Import::Framework::Logger).to receive(:error).with({
          message: 'Failed to load all references to placeholder user contributions',
          error: exception.message,
          import_source: import_source,
          import_uid: uid
        })

        expect_next_instance_of(Import::PlaceholderReferences::Store) do |store|
          expect(store).to receive(:clear!)
        end

        described_class.sidekiq_retries_exhausted_block.call({ 'args' => [import_source, uid] }, exception)
      end

      # This case should not happen, but in case it does, there should still be a relevant error log anyway
      context 'when an import status object does not exist' do
        let(:import_status_record) { nil }
        let(:uid) { -1 }

        it 'still logs the error without an import object to fail' do
          exception = StandardError.new('Some error')

          expect(::Import::Framework::Logger).to receive(:error).with({
            message: 'Failed to load all references to placeholder user contributions',
            error: exception.message,
            import_source: import_source,
            import_uid: uid
          })

          described_class.sidekiq_retries_exhausted_block.call({ 'args' => [import_source, uid] }, exception)
        end
      end
    end

    context 'when import_source is Direct Transfer' do
      let(:import_status_record) { create(:bulk_import, :started) }
      let(:import_source) { 'gitlab' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is GitHub' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'github') }
      let(:import_source) { 'github' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is Bitbucket' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'bitbucket') }
      let(:import_source) { 'bitbucket' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is Bitbucket Server' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'bitbucket_server') }
      let(:import_source) { 'bitbucket_server' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is Gitea' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'gitea') }
      let(:import_source) { 'gitea' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is FogBugz' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'fogbugz') }
      let(:import_source) { 'fogbugz' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is GitLab project export upload' do
      let(:import_status_record) { create(:import_state, :started, project: project, import_type: 'gitlab_project') }
      let(:import_source) { 'gitlab_project' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end

    context 'when import_source is GitLab group export upload' do
      let(:import_status_record) { create(:group_import_state, :started) }
      let(:import_source) { 'import_group_from_file' }
      let(:uid) { import_status_record.id }

      it_behaves_like 'failed user contribution mapping'
    end
  end
end
