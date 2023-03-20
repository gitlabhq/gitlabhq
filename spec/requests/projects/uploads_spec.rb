# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'File uploads', feature_category: :shared do
  include WorkhorseHelpers

  let(:project) { create(:project, :public, :repository) }
  let(:user) { create(:user) }

  describe 'POST /:namespace/:project/create/:branch' do
    let(:branch) { 'master' }
    let(:create_url) { project_blob_path(project, branch) }
    let(:blob_url) { project_blob_path(project, "#{branch}/dk.png") }
    let(:params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: branch,
        branch_name: branch,
        file: fixture_file_upload('spec/fixtures/dk.png'),
        commit_message: 'Add an image'
      }
    end

    before do
      project.add_maintainer(user)

      login_as(user)
    end

    it 'redirects to blob' do
      workhorse_post_with_file(create_url, file_key: :file, params: params)

      expect(response).to redirect_to(blob_url)
    end
  end
end
