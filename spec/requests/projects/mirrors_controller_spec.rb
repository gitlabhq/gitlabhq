require 'spec_helper'

describe Projects::MirrorsController do
  let(:project) do
    create(:project,
           mirror: true,
           mirror_user: user,
           import_url: 'http://user:pass@test.url')
  end
  let(:user) { create(:user) }

  describe 'updates the mirror URL' do
    before do
      project.team << [user, :master]
      login_as(user)
    end

    it 'complains about passing an empty URL' do
      patch namespace_project_mirror_path(project.namespace, project),
        project: {
        mirror: '1',
        import_url: '',
        mirror_user_id: '1',
        mirror_trigger_builds: '0'
      }

      expect(response).to have_http_status :success
      expect(response).to render_template(:show)
      expect(response.body).to include('Import url can&#39;t be blank')
    end
  end
end
