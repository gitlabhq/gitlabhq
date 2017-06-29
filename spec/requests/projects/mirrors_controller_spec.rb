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
      patch project_mirror_path(project),
        project: {
        mirror: '1',
        import_url: '',
        mirror_user_id: '1',
        mirror_trigger_builds: '0'
      }

      expect(response).to have_http_status(302)
      expect(response).to redirect_to(project_settings_repository_path(project))
      expect(flash[:alert]).to include("Import url can't be blank")
    end
  end
end
