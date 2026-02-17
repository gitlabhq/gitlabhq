# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe 'gitlab:permissions rake tasks', feature_category: :permissions do
  before do
    Rake.application.rake_require('tasks/gitlab/permissions/permissions')
  end

  def stub_task_initialization(klass)
    task = instance_double(klass)
    expect(klass).to receive(:new).and_return(task)
    task
  end

  describe 'validate' do
    it 'invokes Gitlab::Permissions::ValidateTask' do
      validate_task = stub_task_initialization(Tasks::Gitlab::Permissions::ValidateTask)
      assignable_validate_task = stub_task_initialization(Tasks::Gitlab::Permissions::Assignable::ValidateTask)
      routes_docs_task = stub_task_initialization(Tasks::Gitlab::Permissions::Routes::DocsTask)

      expect(validate_task).to receive(:run)
      expect(assignable_validate_task).to receive(:run)
      expect(routes_docs_task).to receive(:check_docs)

      run_rake_task('gitlab:permissions:validate')
    end
  end

  describe 'compile_docs' do
    it 'invokes Gitlab::Permissions::Routes::DocsTask' do
      task = stub_task_initialization(Tasks::Gitlab::Permissions::Routes::DocsTask)

      expect(task).to receive(:compile_docs)

      run_rake_task('gitlab:permissions:routes:compile_docs')
    end
  end
end
