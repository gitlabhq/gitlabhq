# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/gitlab/hard_delete_calls'

RSpec.describe RuboCop::Cop::Gitlab::HardDeleteCalls, feature_category: :incident_management do
  it 'registers an offense when using Projects::DestroyService' do
    expect_offense(<<~RUBY)
      Projects::DestroyService.new(project, user).execute
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `Projects::DestroyService`. Use `Projects::MarkForDeletionService` instead. [...]
    RUBY
  end

  it 'registers an offense when using Projects::DestroyWorker' do
    expect_offense(<<~RUBY)
      ProjectDestroyWorker.perform_async(project.id, current_user.id, params)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `ProjectDestroyWorker`. Use `Projects::MarkForDeletionService` instead. [...]
    RUBY
  end

  it 'registers an offense when using Groups::DestroyService' do
    expect_offense(<<~RUBY)
      Groups::DestroyService.new(group, user).execute
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `Groups::DestroyService`. Use `Groups::MarkForDeletionService` instead. [...]
    RUBY
  end

  it 'registers an offense when using GroupDestroyWorker' do
    expect_offense(<<~RUBY)
      GroupDestroyWorker.perform_async(group.id, user.id)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `GroupDestroyWorker`. Use `Groups::MarkForDeletionService` instead. [...]
    RUBY
  end

  context 'when hard delete classes are called with safe navigation' do
    it 'registers an offense for Projects::DestroyService with safe navigation' do
      expect_offense(<<~RUBY)
        def delete_project(project)
          Projects::DestroyService&.new(project, user)&.execute
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid the use of `Projects::DestroyService`. Use `Projects::MarkForDeletionService` instead. [...]
        end
      RUBY
    end
  end
end
