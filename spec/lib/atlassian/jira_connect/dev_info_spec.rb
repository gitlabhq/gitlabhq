# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::DevInfo do
  let_it_be(:project) { create_default(:project, :repository).freeze }

  let(:update_sequence_id) { '123' }

  describe '#url' do
    subject { described_class.new(project: project).url }

    it { is_expected.to eq('/rest/devinfo/0.10/bulk') }
  end

  describe '#body' do
    let_it_be(:merge_request) { create(:merge_request, :unique_branches, title: 'TEST-123') }
    let_it_be(:note) { create(:note, noteable: merge_request, project: merge_request.project) }
    let_it_be(:branches) do
      project.repository.create_branch('TEST-123', project.default_branch_or_main)
      [project.repository.find_branch('TEST-123')]
    end

    let(:merge_requests) { [merge_request] }

    subject(:body) { described_class.new(project: project, branches: branches, merge_requests: merge_requests, update_sequence_id: update_sequence_id).body.to_json }

    it 'matches the schema' do
      expect(body).to match_schema('jira_connect/dev_info')
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new { subject }.count

      merge_requests << create(:merge_request, :unique_branches)

      expect { subject }.not_to exceed_query_limit(control_count)
    end
  end

  describe '#present?' do
    let(:arguments) { { commits: nil, branches: nil, merge_requests: nil } }

    subject { described_class.new(**{ project: project, update_sequence_id: update_sequence_id }.merge(arguments)).present? }

    it { is_expected.to eq(false) }

    context 'with commits, branches or merge requests' do
      let(:arguments) { { commits: anything, branches: anything, merge_requests: anything } }

      it { is_expected.to eq(true) }
    end
  end
end
