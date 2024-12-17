# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/check_docs_task'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/compile_docs_task'

RSpec.describe Tasks::Gitlab::AuditEventTypes::CheckDocsTask, feature_category: :audit_events do
  let(:docs_dir) { Rails.root.join("tmp/tests/doc/administration/audit_event_streaming") }
  let(:docs_path) { Rails.root.join(docs_dir, 'audit_event_types.md') }
  let(:template_erb_path) { Rails.root.join("tooling/audit_events/docs/templates/audit_event_types.md.erb") }

  let(:stub_definitions) do
    expect(Gitlab::Audit::Type::Definition).to receive(:definitions).and_return(updated_definitions)
  end

  describe '#run' do
    before do
      Gitlab::Audit::Type::Definition.clear_memoization(:definitions)
      Tasks::Gitlab::AuditEventTypes::CompileDocsTask.new(docs_dir, docs_path, template_erb_path).run
    end

    let(:new_audit_event) do
      { new_audit_event: instance_double(Gitlab::Audit::Type::Definition,
        name: 'new_audit_event',
        description: 'some description',
        feature_category: 'audit_events',
        introduced_by_mr: 'https://mr',
        introduced_by_issue: 'https://issue',
        milestone: '16.0',
        saved_to_database: true,
        streamed: false,
        scope: ['Project']
      ) }
    end

    let(:added_definition) { Gitlab::Audit::Type::Definition.definitions.merge(new_audit_event) }
    let(:removed_definition) { Gitlab::Audit::Type::Definition.definitions.except(:feature_flag_created) }
    let(:updated_definition) do
      definitions = Gitlab::Audit::Type::Definition.definitions
      definitions[:feature_flag_created].attributes[:saved_to_database] = false

      definitions
    end

    let(:success_message) { "Audit event types documentation is up to date.\n" }
    let(:error_message) do
      "Audit event types documentation is outdated! Please update it " \
        "by running `bundle exec rake gitlab:audit_event_types:compile_docs`"
    end

    it_behaves_like 'checks if the doc is up-to-date'
  end
end
