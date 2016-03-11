require 'spec_helper'

describe API::Todos, api: true do
  include ApiHelpers

  let(:project_1) { create(:project) }
  let(:project_2) { create(:project) }
  let(:author_1) { create(:user) }
  let(:author_2) { create(:user) }
  let(:john_doe) { create(:user, username: 'john_doe') }
  let(:merge_request) { create(:merge_request, source_project: project_1) }
  let!(:pending_1) { create(:todo, project: project_1, author: author_1, user: john_doe) }
  let!(:pending_2) { create(:todo, project: project_2, author: author_2, user: john_doe) }
  let!(:pending_3) { create(:todo, project: project_1, author: author_2, user: john_doe, target: merge_request) }
  let!(:done) { create(:todo, :done, project: project_1, author: author_1, user: john_doe) }

  describe 'GET /todos' do
    context 'when unauthenticated' do
      it 'should return authentication error' do
        get api('/todos')
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should return an array of pending todos for current user' do
        get api('/todos', john_doe)
        expect(response.status).to eq(200)
        expect(json_response).to be_an Array
        expect(json_response.length).to eq(3)
      end

      context 'and using the author filter' do
        it 'should filter based on author_id param' do
          get api('/todos', john_doe), { author_id: author_2.id }
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(2)
        end
      end

      context 'and using the type filter' do
        it 'should filter based on type param' do
          get api('/todos', john_doe), { type: 'MergeRequest' }
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end

      context 'and using the state filter' do
        it 'should filter based on state param' do
          get api('/todos', john_doe), { state: 'done' }
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end

      context 'and using the project filter' do
        it 'should filter based on project_id param' do
          project_2.team << [john_doe, :developer]
          get api('/todos', john_doe), { project_id: project_2.id }
          expect(response.status).to eq(200)
          expect(json_response).to be_an Array
          expect(json_response.length).to eq(1)
        end
      end
    end
  end

  describe 'DELETE /todos/:id' do
    context 'when unauthenticated' do
      it 'should return authentication error' do
        delete api("/todos/#{pending_1.id}")
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should mark a todo as done' do
        delete api("/todos/#{pending_1.id}", john_doe)
        expect(response.status).to eq(200)
        expect(pending_1.reload).to be_done
      end
    end
  end

  describe 'DELETE /todos' do
    context 'when unauthenticated' do
      it 'should return authentication error' do
        delete api('/todos')
        expect(response.status).to eq(401)
      end
    end

    context 'when authenticated' do
      it 'should mark all todos as done' do
        delete api('/todos', john_doe)
        expect(response.status).to eq(200)
        expect(pending_1.reload).to be_done
        expect(pending_2.reload).to be_done
        expect(pending_3.reload).to be_done
      end
    end
  end
end
