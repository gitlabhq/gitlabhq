# frozen_string_literal: true

RSpec.shared_examples 'a harbor repositories controller' do |args|
  include HarborHelper
  let_it_be(:user) { create(:user) }
  let_it_be(:unauthorized_user) { create(:user) }
  let_it_be(:json_header) { { accept: 'application/json' } }

  let(:mock_repositories) do
    [
      {
        artifact_count: 6,
        creation_time: "2022-04-24T10:59:02.719Z",
        id: 33,
        name: "test/photon",
        project_id: 3,
        pull_count: 12,
        update_time: "2022-04-24T11:06:27.678Z"
      },
      {
        artifact_count: 1,
        creation_time: "2022-04-23T08:04:08.880Z",
        id: 1,
        name: "test/gemnasium",
        project_id: 3,
        pull_count: 0,
        update_time: "2022-04-23T08:04:08.880Z"
      }
    ]
  end

  shared_examples 'responds with 404 status' do
    it 'returns 404' do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'responds with 200 status with html' do
    it 'renders the index template' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to render_template(:index)
    end
  end

  shared_examples 'responds with 302 status' do
    it 'returns 302' do
      subject

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  shared_examples 'responds with 200 status with json' do
    it 'renders the index template' do
      subject

      expect(response).to have_gitlab_http_status(:ok)
      expect(response).not_to render_template(:index)
    end
  end

  shared_examples 'responds with 422 status with json' do
    it 'returns 422' do
      subject

      expect(response).to have_gitlab_http_status(:unprocessable_entity)
    end
  end

  before do
    stub_request(:get, "https://demo.goharbor.io/api/v2.0/projects/testproject/repositories?page=1&page_size=10")
      .with(
        headers: {
      Authorization: 'Basic aGFyYm9ydXNlcm5hbWU6aGFyYm9ycGFzc3dvcmQ=',
      'Content-Type': 'application/json'
      }).to_return(status: 200, body: mock_repositories.to_json, headers: { "x-total-count": 2 })
    container.add_reporter(user)
    sign_in(user)
  end

  describe 'GET #index.html' do
    subject do
      get harbor_repository_url(container)
    end

    it_behaves_like 'responds with 200 status with html'

    context 'with anonymous user' do
      before do
        sign_out(user)
      end

      it_behaves_like "responds with #{args[:anonymous_status_code]} status"
    end

    context 'with unauthorized user' do
      before do
        sign_in(unauthorized_user)
      end

      it_behaves_like 'responds with 404 status'
    end
  end

  describe 'GET #index.json' do
    subject do
      get harbor_repository_url(container), headers: json_header
    end

    it_behaves_like 'responds with 200 status with json'

    context 'with valid params' do
      context 'with valid page params' do
        subject do
          get harbor_repository_url(container, page: '1'), headers: json_header
        end

        it_behaves_like 'responds with 200 status with json'
      end

      context 'with valid limit params' do
        subject do
          get harbor_repository_url(container, limit: '10'), headers: json_header
        end

        it_behaves_like 'responds with 200 status with json'
      end
    end

    context 'with invalid params' do
      context 'with invalid page params' do
        subject do
          get harbor_repository_url(container, page: 'aaa'), headers: json_header
        end

        it_behaves_like 'responds with 422 status with json'
      end

      context 'with invalid limit params' do
        subject do
          get harbor_repository_url(container, limit: 'aaa'), headers: json_header
        end

        it_behaves_like 'responds with 422 status with json'
      end
    end
  end
end
