# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::IncidentManagement::PagerDuty::IncidentIssueDescription do
  describe '#to_s' do
    let(:markdown_line_break) { '  ' }
    let(:created_at) { '2017-09-26T15:14:36Z' }
    let(:assignees) do
      [{ 'summary' => 'Laura Haley', 'url' => 'https://webdemo.pagerduty.com/users/P553OPV' }]
    end

    let(:impacted_service) do
      { 'summary' => 'Production XDB Cluster', 'url' => 'https://webdemo.pagerduty.com/services/PN49J75' }
    end

    let(:incident_payload) do
      {
        'url' => 'https://webdemo.pagerduty.com/incidents/PRORDTY',
        'incident_number' => 33,
        'title' => 'My new incident',
        'status' => 'triggered',
        'created_at' => created_at,
        'urgency' => 'high',
        'incident_key' => 'SOME-KEY',
        'assignees' => assignees,
        'impacted_service' => impacted_service
      }
    end

    subject(:description) { described_class.new(incident_payload).to_s }

    it 'returns description' do
      expect(description).to eq(
        <<~MARKDOWN.chomp
          **Incident:** [My new incident](https://webdemo.pagerduty.com/incidents/PRORDTY)#{markdown_line_break}
          **Incident number:** 33#{markdown_line_break}
          **Urgency:** high#{markdown_line_break}
          **Status:** triggered#{markdown_line_break}
          **Incident key:** SOME-KEY#{markdown_line_break}
          **Created at:** 26 September 2017, 3:14PM (UTC)#{markdown_line_break}
          **Assignees:** [Laura Haley](https://webdemo.pagerduty.com/users/P553OPV)#{markdown_line_break}
          **Impacted service:** [Production XDB Cluster](https://webdemo.pagerduty.com/services/PN49J75)
        MARKDOWN
      )
    end

    context 'when created_at is missing' do
      let(:created_at) { nil }

      it 'description contains current time in UTC' do
        freeze_time do
          now = Time.current.utc.strftime('%d %B %Y, %-l:%M%p (%Z)')

          expect(description).to include(
            <<~MARKDOWN.chomp
            **Created at:** #{now}#{markdown_line_break}
            MARKDOWN
          )
        end
      end
    end

    context 'when there are several assignees' do
      let(:assignees) do
        [
          { 'summary' => 'Laura Haley', 'url' => 'https://laura.pagerduty.com' },
          { 'summary' => 'John Doe', 'url' => 'https://john.pagerduty.com' }
        ]
      end

      it 'assignees is a list of links' do
        expect(description).to include(
          <<~MARKDOWN.chomp
            **Assignees:** [Laura Haley](https://laura.pagerduty.com), [John Doe](https://john.pagerduty.com)#{markdown_line_break}
          MARKDOWN
        )
      end
    end

    context 'when there is an impacted service' do
      let(:impacted_service) do
        { 'summary' => 'XDB Cluster', 'url' => 'https://xdb.pagerduty.com' }
      end

      it 'impacted service is a single link' do
        expect(description).to include(
          <<~MARKDOWN.chomp
            **Impacted service:** [XDB Cluster](https://xdb.pagerduty.com)
          MARKDOWN
        )
      end
    end
  end
end
