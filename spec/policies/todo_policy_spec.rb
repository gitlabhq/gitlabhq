# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodoPolicy, feature_category: :notifications do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:author) { create(:user) }

  def permissions(user, todo)
    described_class.new(user, todo)
  end

  shared_examples 'grants the expected permissions' do |policy|
    it do
      if allowed
        expect(permissions(user, todo)).to be_allowed(policy)
      else
        expect(permissions(user, todo)).to be_disallowed(policy)
      end
    end
  end

  describe 'own_todo' do
    let_it_be(:user1) { create(:user) }
    let_it_be(:user2) { create(:user) }
    let_it_be(:user3) { create(:user) }

    let_it_be(:todo1) { create(:todo, author: author, user: user1, issue: issue) }
    let_it_be(:todo2) { create(:todo, author: author, user: user2, issue: issue) }
    let_it_be(:todo3) { create(:todo, author: author, user: user2) }
    let_it_be(:todo4) { create(:todo, author: author, user: user3, issue: issue) }

    where(:user, :todo, :allowed) do
      ref(:user1) | ref(:todo1) | true
      ref(:user2) | ref(:todo2) | true
      ref(:user1) | ref(:todo2) | false
      ref(:user1) | ref(:todo3) | false
      ref(:user2) | ref(:todo1) | false
      ref(:user2) | ref(:todo4) | false
      ref(:user3) | ref(:todo1) | false
      ref(:user3) | ref(:todo2) | false
      ref(:user3) | ref(:todo3) | false
      ref(:user3) | ref(:todo4) | false
      ref(:user2) | ref(:todo3) | false
    end

    before_all do
      project.add_developer(user1)
      project.add_developer(user2)
    end

    with_them do
      it_behaves_like 'grants the expected permissions', :read_todo
    end
  end

  describe 'read_note' do
    let_it_be(:non_member) { create(:user) }
    let_it_be(:guest) { create(:user) }
    let_it_be(:reporter) { create(:user) }

    let_it_be(:note) { create(:note, noteable: issue, project: project) }
    let_it_be(:internal) { create(:note, :confidential, noteable: issue, project: project) }

    let_it_be(:no_note_todo1) { create(:todo, author: author, user: reporter, issue: issue) }
    let_it_be(:note_todo1) { create(:todo, note: note, author: author, user: reporter, issue: issue) }
    let_it_be(:internal_note_todo1) { create(:todo, note: internal, author: author, user: reporter, issue: issue) }

    let_it_be(:no_note_todo2) { create(:todo, author: author, user: guest, issue: issue) }
    let_it_be(:note_todo2) { create(:todo, note: note, author: author, user: guest, issue: issue) }
    let_it_be(:internal_note_todo2) { create(:todo, note: internal, author: author, user: guest, issue: issue) }

    let_it_be(:no_note_todo3) { create(:todo, author: author, user: non_member, issue: issue) }
    let_it_be(:note_todo3) { create(:todo, note: note, author: author, user: non_member, issue: issue) }
    let_it_be(:internal_note_todo3) { create(:todo, note: internal, author: author, user: non_member, issue: issue) }

    where(:user, :todo, :allowed) do
      ref(:reporter)   | ref(:no_note_todo1)       | true
      ref(:reporter)   | ref(:note_todo1)          | true
      ref(:reporter)   | ref(:internal_note_todo1) | true
      ref(:guest)      | ref(:no_note_todo2)       | true
      ref(:guest)      | ref(:note_todo2)          | true
      ref(:guest)      | ref(:internal_note_todo2) | false
      ref(:non_member) | ref(:no_note_todo3)       | false
      ref(:non_member) | ref(:note_todo3)          | false
      ref(:non_member) | ref(:internal_note_todo3) | false
    end

    before_all do
      project.add_guest(guest)
      project.add_reporter(reporter)
    end

    with_them do
      it_behaves_like 'grants the expected permissions', :read_todo
      it_behaves_like 'grants the expected permissions', :update_todo
    end
  end
end
