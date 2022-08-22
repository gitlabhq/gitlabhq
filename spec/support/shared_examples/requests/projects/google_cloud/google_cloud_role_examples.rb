# frozen_string_literal: true

RSpec.shared_examples 'requires `admin_project_google_cloud` role' do
  shared_examples 'returns not_found' do
    it 'returns not found' do
      sign_in(user)

      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'redirects to authorize url' do
    it 'redirects to authorize url' do
      sign_in(user)

      subject

      expect(response).to redirect_to(assigns(:authorize_url))
    end
  end

  context 'when requested by users with different roles' do
    let_it_be(:guest) { create(:user) }
    let_it_be(:developer) { create(:user) }
    let_it_be(:maintainer) { create(:user) }

    before do
      project.add_guest(guest)
      project.add_developer(developer)
      project.add_maintainer(maintainer)
    end

    context 'for unauthorized users' do
      include_examples 'returns not_found' do
        let(:user) { guest }
      end

      include_examples 'returns not_found' do
        let(:user) { developer }
      end
    end

    context 'for authorized users' do
      include_examples 'redirects to authorize url' do
        let(:user) { maintainer }
      end

      include_examples 'redirects to authorize url' do
        let(:user) { project.owner }
      end
    end
  end
end
