require 'spec_helper'

describe API::V3::Todos do
  let(:project_1) { create(:project) }
  let(:project_2) { create(:project) }
  let(:author_1) { create(:user) }
  let(:author_2) { create(:user) }
  let(:john_doe) { create(:user, username: 'john_doe') }
  let!(:pending_1) { create(:todo, :mentioned, project: project_1, author: author_1, user: john_doe) }
  let!(:pending_2) { create(:todo, project: project_2, author: author_2, user: john_doe) }
  let!(:pending_3) { create(:todo, project: project_1, author: author_2, user: john_doe) }
  let!(:done) { create(:todo, :done, project: project_1, author: author_1, user: john_doe) }

  before do
    project_1.add_developer(john_doe)
    project_2.add_developer(john_doe)
  end

  describe 'DELETE /todos/:id' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete v3_api("/todos/#{pending_1.id}")

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'marks a todo as done' do
        delete v3_api("/todos/#{pending_1.id}", john_doe)

        expect(response.status).to eq(200)
        expect(pending_1.reload).to be_done
      end

      it 'updates todos cache' do
        expect_any_instance_of(User).to receive(:update_todos_count_cache).and_call_original

        delete v3_api("/todos/#{pending_1.id}", john_doe)
      end

      it 'returns 404 if the todo does not belong to the current user' do
        delete v3_api("/todos/#{pending_1.id}", author_1)

        expect(response.status).to eq(404)
      end
    end
  end

  describe 'DELETE /todos' do
    context 'when unauthenticated' do
      it 'returns authentication error' do
        delete v3_api('/todos')

        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'marks all todos as done' do
        delete v3_api('/todos', john_doe)

        expect(response.status).to eq(200)
        expect(response.body).to eq('3')
        expect(pending_1.reload).to be_done
        expect(pending_2.reload).to be_done
        expect(pending_3.reload).to be_done
      end

      it 'updates todos cache' do
        expect_any_instance_of(User).to receive(:update_todos_count_cache).and_call_original

        delete v3_api("/todos", john_doe)
      end
    end
  end
end
