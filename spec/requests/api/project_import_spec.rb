require 'spec_helper'

describe API::ProjectImport do
  let(:export_path) { "#{Dir.tmpdir}/project_export_spec" }
  let(:user) { create(:user) }
  let(:file) { File.join(Rails.root, 'spec', 'features', 'projects', 'import_export', 'test_project_export.tar.gz') }
  let(:namespace) { create(:group) }
  before do
    allow_any_instance_of(Gitlab::ImportExport).to receive(:storage_path).and_return(export_path)

    group.add_owner(user)
  end

  after do
    FileUtils.rm_rf(export_path, secure: true)
  end

  describe 'POST /projects/import' do

    it 'schedules an import' do
      expect_any_instance_of(Project).to receive(:import_schedule)

      post api('/projects/import', user), file: file, namespace: namespace.full_path

      expect(project.status).to eq('started')
    end
  end

  describe 'GET /projects/:id/import' do
    it 'returns the import status' do
      project = create(:project, import_status: 'started')

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'started')
    end

    it 'returns the import status and the error if failed' do
      project = create(:project, import_status: 'failed', import_error: 'error')

      get api("/projects/#{project.id}/import", user)

      expect(response).to have_gitlab_http_status(200)
      expect(json_response).to include('import_status' => 'failed',
                                  'import_error' => 'error')
    end
  end
end
