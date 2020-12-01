# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Client do
  include StubRequests

  subject { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

  around do |example|
    freeze_time { example.run }
  end

  describe '.generate_update_sequence_id' do
    it 'returns monotonic_time converted it to integer' do
      allow(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(1.0)

      expect(described_class.generate_update_sequence_id).to eq(1)
    end
  end

  describe '#store_dev_info' do
    let_it_be(:project) { create_default(:project, :repository) }
    let_it_be(:merge_requests) { create_list(:merge_request, 2, :unique_branches) }

    let(:expected_jwt) do
      Atlassian::Jwt.encode(
        Atlassian::Jwt.build_claims(
          Atlassian::JiraConnect.app_key,
          '/rest/devinfo/0.10/bulk',
          'POST'
        ),
        'sample_secret'
      )
    end

    before do
      stub_full_request('https://gitlab-test.atlassian.net/rest/devinfo/0.10/bulk', method: :post)
        .with(
          headers: {
            'Authorization' => "JWT #{expected_jwt}",
            'Content-Type' => 'application/json'
          }
        )
    end

    it "calls the API with auth headers" do
      subject.store_dev_info(project: project)
    end

    it 'avoids N+1 database queries' do
      control_count = ActiveRecord::QueryRecorder.new { subject.store_dev_info(project: project, merge_requests: merge_requests) }.count

      merge_requests << create(:merge_request, :unique_branches)

      expect { subject.store_dev_info(project: project, merge_requests: merge_requests) }.not_to exceed_query_limit(control_count)
    end
  end
end
