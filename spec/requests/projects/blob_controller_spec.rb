# frozen_string_literal: true

require 'spec_helper'

describe Projects::BlobController do
  let(:project) { create(:project, :private, :repository) }
  let(:namespace) { project.namespace }

  context 'anonymous user views blob in inaccessible project' do
    context 'with default HTML format' do
      before do
        get namespace_project_blob_path(namespace_id: namespace, project_id: project, id: 'master/README.md')
      end

      context 'when project is private' do
        it { expect(response).to have_gitlab_http_status(:redirect) }
      end

      context 'when project does not exist' do
        let(:namespace) { 'non_existent_namespace' }
        let(:project)   { 'non_existent_project' }

        it { expect(response).to have_gitlab_http_status(:redirect) }
      end
    end

    context 'with JSON format' do
      before do
        get namespace_project_blob_path(namespace_id: namespace, project_id: project, id: 'master/README.md', format: :json)
      end

      context 'when project is private' do
        it { expect(response).to have_gitlab_http_status(:unauthorized) }
      end

      context 'when project does not exist' do
        let(:namespace) { 'non_existent_namespace' }
        let(:project)   { 'non_existent_project' }

        it { expect(response).to have_gitlab_http_status(:unauthorized) }
      end
    end
  end
end
