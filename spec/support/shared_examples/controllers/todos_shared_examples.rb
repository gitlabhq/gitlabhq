# frozen_string_literal: true

RSpec.shared_examples 'todos actions' do
  context 'when authorized' do
    before do
      sign_in(user)
      parent.add_developer(user)
    end

    it 'creates todo' do
      expect do
        post_create
      end.to change { user.todos.count }.by(1)

      expect(response).to have_gitlab_http_status(:ok)
    end

    it 'returns todo path and pending count' do
      post_create

      expect(response).to have_gitlab_http_status(:ok)
      expect(json_response['count']).to eq 1
      expect(json_response['delete_path']).to match(%r{/dashboard/todos/\d{1}})
    end
  end

  context 'when not authorized for project/group' do
    it 'does not create todo for resource that user has no access to' do
      sign_in(user)
      expect do
        post_create
      end.to change { user.todos.count }.by(0)

      expect(response).to have_gitlab_http_status(:not_found)
    end

    it 'does not create todo when user is not logged in' do
      expect do
        post_create
      end.to change { user.todos.count }.by(0)

      expect(response).to have_gitlab_http_status(:found)
    end
  end
end
