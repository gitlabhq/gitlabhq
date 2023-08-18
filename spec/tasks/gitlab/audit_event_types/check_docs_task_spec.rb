# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/check_docs_task'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/compile_docs_task'

RSpec.describe Tasks::Gitlab::AuditEventTypes::CheckDocsTask, feature_category: :audit_events do
  let_it_be(:docs_dir) { Rails.root.join("tmp/tests/doc/administration/audit_event_streaming") }
  let_it_be(:docs_path) { Rails.root.join(docs_dir, 'audit_event_types.md') }
  let_it_be(:template_erb_path) { Rails.root.join("tooling/audit_events/docs/templates/audit_event_types.md.erb") }

  subject(:check_docs_task) { described_class.new(docs_dir, docs_path, template_erb_path) }

  describe '#run' do
    before do
      Gitlab::Audit::Type::Definition.clear_memoization(:definitions)
      Tasks::Gitlab::AuditEventTypes::CompileDocsTask.new(docs_dir, docs_path, template_erb_path).run
    end

    context 'when audit_event_types.md is up to date' do
      it 'outputs success message after checking the documentation' do
        expect { subject.run }.to output("Audit event types documentation is up to date.\n").to_stdout
      end
    end

    context 'when audit_event_types.md is updated manually' do
      before do
        File.write(docs_path, "Manually adding this line at the end of the audit_event_types.md", mode: 'a+')
      end

      it 'raises an error' do
        expected_output = "Audit event types documentation is outdated! Please update it " \
                          "by running `bundle exec rake gitlab:audit_event_types:compile_docs`"

        expect { subject.run }.to raise_error(SystemExit).and output(/#{expected_output}/).to_stdout
      end
    end

    context 'when an existing audit event type is removed' do
      let_it_be(:updated_definition) { Gitlab::Audit::Type::Definition.definitions.except(:feature_flag_created) }

      it 'raises an error' do
        expect(Gitlab::Audit::Type::Definition).to receive(:definitions).and_return(updated_definition)

        expected_output = "Audit event types documentation is outdated! Please update it " \
                          "by running `bundle exec rake gitlab:audit_event_types:compile_docs`"

        expect { subject.run }.to raise_error(SystemExit).and output(/#{expected_output}/).to_stdout
      end
    end

    context 'when an existing audit event type is updated' do
      let_it_be(:updated_definition) { Gitlab::Audit::Type::Definition.definitions }

      it 'raises an error' do
        updated_definition[:feature_flag_created].attributes[:streamed] = false

        expect(Gitlab::Audit::Type::Definition).to receive(:definitions).and_return(updated_definition)

        expected_output = "Audit event types documentation is outdated! Please update it " \
                          "by running `bundle exec rake gitlab:audit_event_types:compile_docs`"

        expect { subject.run }.to raise_error(SystemExit).and output(/#{expected_output}/).to_stdout
      end
    end
  end
end
