require 'spec_helper'
require Rails.root.join('db', 'migrate', '20180201110056_add_foreign_keys_to_todos.rb')

describe AddForeignKeysToTodos, :migration do
  let(:todos) { table(:todos) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }

  let(:project) { projects.create!(name: 'gitlab', path: 'gitlab-org/gitlab-ce', namespace_id: 1) }
  let(:user) { users.create!(email: 'email@email.com', name: 'foo', username: 'foo', projects_limit: 0) }

  context 'add foreign key on user_id' do
    let!(:todo_with_user) { create_todo(user_id: user.id) }
    let!(:todo_without_user) { create_todo(user_id: 4711) }

    it 'removes orphaned todos without corresponding user' do
      expect { migrate! }.to change { Todo.count }.from(2).to(1)
    end

    it 'does not remove entries with valid user_id' do
      expect { migrate! }.not_to change { todo_with_user.reload }
    end
  end

  context 'add foreign key on author_id' do
    let!(:todo_with_author) { create_todo(author_id: user.id) }
    let!(:todo_with_invalid_author) { create_todo(author_id: 4711) }

    it 'removes orphaned todos by author_id' do
      expect { migrate! }.to change { Todo.count }.from(2).to(1)
    end

    it 'does not touch author_id for valid entries' do
      expect { migrate! }.not_to change { todo_with_author.reload }
    end
  end

  context 'add foreign key on note_id' do
    let(:note) { table(:notes).create! }
    let!(:todo_with_note) { create_todo(note_id: note.id) }
    let!(:todo_with_invalid_note) { create_todo(note_id: 4711) }
    let!(:todo_without_note) { create_todo(note_id: nil) }

    it 'deletes todo if note_id is set but does not exist in notes table' do
      expect { migrate! }.to change { Todo.count }.from(3).to(2)
    end

    it 'does not touch entry if note_id is nil' do
      expect { migrate! }.not_to change { todo_without_note.reload }
    end

    it 'does not touch note_id for valid entries' do
      expect { migrate! }.not_to change { todo_with_note.reload }
    end
  end

  def create_todo(**opts)
    todos.create!(
      project_id: project.id,
      user_id: user.id,
      author_id: user.id,
      target_type: '',
      action: 0,
      state: '', **opts
    )
  end
end
