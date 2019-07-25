# frozen_string_literal: true

shared_examples 'todos actions' do
  context 'when authorized' do
    before do
      sign_in(user)
      parent.add_developer(user)
    end

    it 'creates todo' do
      expect do
        post_create
      end.to change { user.todos.count }.by(1)

      expect(response).to have_gitlab_http_status(200)
    end

    it 'returns todo path and pending count' do
      post_create

      expect(response).to have_gitlab_http_status(200)
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

      expect(response).to have_gitlab_http_status(404)
    end

    it 'does not create todo when user is not logged in' do
      expect do
        post_create
      end.to change { user.todos.count }.by(0)

      expect(response).to have_gitlab_http_status(parent.is_a?(Group) ? 401 : 302)
    end
  end
end
