# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/check_docs_task'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/compile_docs_task'

RSpec.describe 'gitlab:audit_event_types rake tasks', :silence_stdout, feature_category: :audit_events do
  before do
    Rake.application.rake_require('tasks/gitlab/audit_event_types/audit_event_types')
    stub_env('VERBOSE' => 'true')
    Gitlab::Audit::Type::Definition.clear_memoization(:definitions)
  end

  describe 'compile_docs' do
    it 'invokes Gitlab::AuditEventTypes::CompileDocsTask with correct arguments' do
      compile_docs_task = instance_double(Tasks::Gitlab::AuditEventTypes::CompileDocsTask)

      expect(Tasks::Gitlab::AuditEventTypes::CompileDocsTask).to receive(:new).with(
        Rails.root.join("doc/user/compliance"),
        Rails.root.join("doc/user/compliance/audit_event_types.md"),
        Rails.root.join("tooling/audit_events/docs/templates/audit_event_types.md.erb")).and_return(compile_docs_task)

      expect(compile_docs_task).to receive(:run)

      run_rake_task('gitlab:audit_event_types:compile_docs')
    end
  end

  describe 'check_docs' do
    it 'invokes Gitlab::AuditEventTypes::CheckDocsTask with correct arguments' do
      check_docs_task = instance_double(Tasks::Gitlab::AuditEventTypes::CheckDocsTask)

      expect(Tasks::Gitlab::AuditEventTypes::CheckDocsTask).to receive(:new).with(
        Rails.root.join("doc/user/compliance"),
        Rails.root.join("doc/user/compliance/audit_event_types.md"),
        Rails.root.join("tooling/audit_events/docs/templates/audit_event_types.md.erb")).and_return(check_docs_task)

      expect(check_docs_task).to receive(:run)

      run_rake_task('gitlab:audit_event_types:check_docs')
    end
  end
end
