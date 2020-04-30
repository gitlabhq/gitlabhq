# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::JiraImport::BaseImporter do
  include JiraServiceHelper

  let(:project) { create(:project) }

  describe 'with any inheriting class' do
    context 'when an error is returned from the project validation' do
      before do
        stub_feature_flags(jira_issue_import: false)

        allow(project).to receive(:validate_jira_import_settings!)
          .and_raise(Projects::ImportService::Error, 'Jira import feature is disabled.')
      end

      it 'raises exception' do
        expect { described_class.new(project) }.to raise_error(Projects::ImportService::Error, 'Jira import feature is disabled.')
      end
    end

    context 'when project validation is ok' do
      let!(:jira_service) { create(:jira_service, project: project) }

      before do
        stub_feature_flags(jira_issue_import: true)
        stub_jira_service_test

        allow(project).to receive(:validate_jira_import_settings!)
      end

      context 'when Jira service exists' do
        context 'when Jira import data is not present' do
          it 'raises exception' do
            expect { described_class.new(project) }.to raise_error(Projects::ImportService::Error, 'Unable to find Jira project to import data from.')
          end
        end

        context 'when import data exists' do
          let_it_be(:project) { create(:project) }
          let_it_be(:jira_import) { create(:jira_import_state, project: project) }
          let(:subject) { described_class.new(project) }

          context 'when #imported_items_cache_key is not implemented' do
            it { expect { subject.send(:imported_items_cache_key) }.to raise_error(NotImplementedError) }
          end

          context 'when #imported_items_cache_key is implemented' do
            before do
              allow(subject).to receive(:imported_items_cache_key).and_return('dumb-importer-key')
            end

            describe '#imported_items_cache_key' do
              it { expect(subject.send(:imported_items_cache_key)).to eq('dumb-importer-key') }
            end

            describe '#mark_as_imported', :clean_gitlab_redis_cache do
              it 'stores id in redis cache' do
                expect(Gitlab::Cache::Import::Caching).to receive(:set_add).once.and_call_original

                subject.send(:mark_as_imported, 'some-id')

                expect(Gitlab::Cache::Import::Caching.set_includes?(subject.send(:imported_items_cache_key), 'some-id')).to be true
              end
            end

            describe '#already_imported?', :clean_gitlab_redis_cache do
              it 'returns false if value is not in cache' do
                expect(Gitlab::Cache::Import::Caching).to receive(:set_includes?).once.and_call_original

                expect(subject.send(:already_imported?, 'some-id')).to be false
              end

              it 'returns true if value already stored in cache' do
                Gitlab::Cache::Import::Caching.set_add(subject.send(:imported_items_cache_key), 'some-id')

                expect(subject.send(:already_imported?, 'some-id')).to be true
              end
            end
          end
        end
      end
    end
  end
end
