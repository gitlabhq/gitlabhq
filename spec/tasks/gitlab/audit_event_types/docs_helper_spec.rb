# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../lib/tasks/gitlab/audit_event_types/docs_helper'

RSpec.describe Tasks::Gitlab::AuditEventTypes::DocsHelper, feature_category: :audit_events do
  subject(:helper) { Class.new { include Tasks::Gitlab::AuditEventTypes::DocsHelper }.new }

  describe '#boolean_to_docs' do
    it 'returns the yes shortcode for true' do
      expect(helper.boolean_to_docs(true)).to eq('{{< yes >}}')
    end

    it 'returns the no shortcode for false' do
      expect(helper.boolean_to_docs(false)).to eq('{{< no >}}')
    end

    it 'returns the no shortcode for nil' do
      expect(helper.boolean_to_docs(nil)).to eq('{{< no >}}')
    end
  end

  describe '#humanize_feature_category' do
    it 'returns the correct label for duo_workflow' do
      expect(helper.humanize_feature_category('duo_workflow')).to eq('GitLab Duo Agent Platform')
    end

    it 'returns the correct label for mlops' do
      expect(helper.humanize_feature_category('mlops')).to eq('MLOps')
    end

    it 'returns the correct label for not_owned' do
      expect(helper.humanize_feature_category('not_owned')).to eq('Not categorized')
    end

    it 'returns the correct label for service_desk' do
      expect(helper.humanize_feature_category('service_desk')).to eq('Service Desk')
    end

    it 'uppercases AI when the category starts with ai_' do
      expect(helper.humanize_feature_category('ai_framework')).to eq('AI framework')
    end

    it 'uppercases AI when the category contains _ai_' do
      expect(helper.humanize_feature_category('some_ai_feature')).to eq('Some AI feature')
    end

    it 'humanizes an ordinary category without modification' do
      expect(helper.humanize_feature_category('source_code_management')).to eq('Source code management')
    end
  end
end
