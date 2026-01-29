# frozen_string_literal: true

require "spec_helper"

RSpec.describe Integrations::UnifyCircuit, feature_category: :integrations do
  it_behaves_like "chat integration", "Unify Circuit" do
    let(:client_arguments) { webhook_url }
    let(:payload) do
      {
        subject: project.full_name,
        text: be_present,
        markdown: true
      }
    end
  end

  describe '.supported_events' do
    it 'includes all supported events' do
      expect(described_class.supported_events).to contain_exactly(
        'push', 'issue', 'confidential_issue', 'work_item', 'confidential_work_item', 'merge_request',
        'note', 'confidential_note', 'tag_push', 'pipeline', 'wiki_page'
      )
    end
  end
end
