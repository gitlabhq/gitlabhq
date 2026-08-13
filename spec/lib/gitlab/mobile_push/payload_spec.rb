# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MobilePush::Payload, feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:author) { create(:user, name: 'Jane Doe') }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project, title: 'Fix the frobnicator') }

  let(:todo) { create(:todo, user: user, author: author, project: project, target: issue) }

  subject(:payload) { described_class.new(todo) }

  describe '#title' do
    it 'uses the target title' do
      expect(payload.title).to eq('Fix the frobnicator')
    end

    context 'when the target has no title' do
      before do
        allow(issue).to receive(:title).and_return(nil)
        allow(todo).to receive(:target).and_return(issue)
      end

      it 'falls back to the target reference' do
        expect(payload.title).to eq("##{issue.iid}")
      end
    end
  end

  describe '#subtitle' do
    it 'combines the full path and the reference' do
      expect(payload.subtitle).to eq("#{project.full_path} · ##{issue.iid}")
    end
  end

  describe '#body' do
    it 'combines the author name and the action phrase' do
      expect(payload.body).to eq('Jane Doe assigned you.')
    end

    context 'when the action phrase is a standalone sentence' do
      let(:todo) { create(:todo, :build_failed, user: user, author: author, project: project) }

      it 'omits the author, mirroring the app' do
        expect(payload.body).to eq('The pipeline failed.')
      end
    end

    context 'when the action has no curated phrase' do
      before do
        allow(todo).to receive(:action_name).and_return(:frobnicated_widget)
      end

      it 'humanizes the action name like the app fallback' do
        expect(payload.body).to eq('Jane Doe frobnicated widget.')
      end
    end
  end

  describe '#badge' do
    it 'is the pending to-do count of the recipient' do
      todo

      expect(payload.badge).to eq(1)
    end
  end

  describe '#thread_id' do
    it 'is the full path plus the reference' do
      expect(payload.thread_id).to eq("#{project.full_path}##{issue.iid}")
    end
  end

  describe '#collapse_id' do
    it 'is derived from the todo id' do
      expect(payload.collapse_id).to eq("todo-#{todo.id}")
    end
  end

  describe '#gitlab_data' do
    it 'carries the structured todo attributes' do
      expect(payload.gitlab_data).to eq(
        version: 1,
        type: 'todo',
        todo_id: todo.id,
        user_id: user.id,
        action: 'assigned',
        target_type: 'Issue',
        project_path: project.full_path,
        iid: issue.iid,
        target_url: Gitlab::UrlBuilder.build(issue),
        note_id: nil
      )
    end

    context 'when the todo is attached to a note' do
      let_it_be(:note) { create(:note_on_issue, project: project, noteable: issue) }

      let(:todo) do
        create(:todo, :mentioned, user: user, author: author, project: project, target: issue, note: note)
      end

      it 'exposes the note id' do
        expect(payload.gitlab_data[:note_id]).to eq(note.id)
      end
    end
  end

  describe '#mutable_content?' do
    it 'is false in full mode' do
      expect(payload.mutable_content?).to be(false)
    end
  end

  describe 'id_only mode' do
    subject(:payload) { described_class.new(todo, mode: :id_only) }

    it 'is id_only' do
      expect(payload).to be_id_only
    end

    it 'carries no todo content in the alert fields' do
      expect(payload.title).to be_nil
      expect(payload.subtitle).to be_nil
      expect(payload.thread_id).to be_nil
      expect(payload.body).to eq('You have a new to-do')
    end

    it 'keeps the badge' do
      todo

      expect(payload.badge).to eq(1)
    end

    it 'keeps the collapse id' do
      expect(payload.collapse_id).to eq("todo-#{todo.id}")
    end

    it 'requests mutable content so the app can render on-device' do
      expect(payload.mutable_content?).to be(true)
    end

    it 'restricts the gitlab dict to identifiers' do
      expect(payload.gitlab_data).to eq(
        version: 1,
        type: 'todo',
        todo_id: todo.id,
        user_id: user.id
      )
    end
  end
end
