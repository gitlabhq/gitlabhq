# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::GitlabProjectsImportService, feature_category: :importers do
  let_it_be(:namespace) { create(:namespace) }

  let(:path) { 'test-path' }
  let(:file) { fixture_file_upload('spec/fixtures/project_export.tar.gz') }
  let(:overwrite) { false }
  let(:import_params) { { namespace_id: namespace.id, path: path, file: file, overwrite: overwrite } }

  subject { described_class.new(namespace.owner, import_params, import_type: 'gitlab_project') }

  before do
    stub_application_setting(import_sources: ['gitlab_project'])
  end

  describe '#execute' do
    it_behaves_like 'gitlab projects import validations', import_type: 'gitlab_project'

    describe 'request_channel', :clean_gitlab_redis_shared_state, :request_store do
      it 'is captured on the import state when given' do
        project = described_class.new(
          namespace.owner, import_params, import_type: 'gitlab_project', request_channel: :ui
        ).execute

        expect(project.import_state.request_channel).to eq('ui')
      end

      it 'is not captured when not given' do
        project = described_class.new(namespace.owner, import_params, import_type: 'gitlab_project').execute

        expect(project.import_state.request_channel).to be_nil
      end
    end
  end
end
