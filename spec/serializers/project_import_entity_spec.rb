# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectImportEntity, feature_category: :importers do
  include ImportHelper

  let_it_be(:project) { create(:project, import_status: :started, import_source: 'import_user/project') }

  let(:provider_url) { 'https://provider.com' }
  let(:client) { nil }
  let(:entity) { described_class.represent(project, provider_url: provider_url, client: client) }

  before do
    create(:import_failure, project: project)
  end

  describe '#as_json' do
    subject { entity.as_json }

    it 'includes required fields' do
      expect(subject[:import_source]).to eq(project.import_source)
      expect(subject[:import_status]).to eq(project.import_status)
      expect(subject[:human_import_status_name]).to eq(project.human_import_status_name)
      expect(subject[:provider_link]).to eq(provider_project_link_url(provider_url, project[:import_source]))
      expect(subject[:import_error]).to eq(nil)
      expect(subject[:relation_type]).to eq(nil)
    end

    context 'when client option present', :clean_gitlab_redis_cache do
      let(:octokit) { instance_double(Octokit::Client, access_token: 'stub') }
      let(:client) do
        instance_double(
          ::Gitlab::GithubImport::Clients::Proxy,
          user: { login: 'import_user' }, octokit: octokit
        )
      end

      it 'includes relation_type' do
        expect(subject[:relation_type]).to eq('owned')
      end
    end

    context 'when import is failed' do
      let!(:last_import_failure) { create(:import_failure, project: project, exception_message: 'LAST ERROR') }

      before do
        project.import_state.fail_op!
      end

      it 'includes only the last import failure' do
        expect(subject[:import_error]).to eq(last_import_failure.exception_message)
      end
    end
  end
end
