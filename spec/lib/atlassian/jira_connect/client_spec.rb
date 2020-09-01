# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Client do
  include StubRequests

  subject { described_class.new('https://gitlab-test.atlassian.net', 'sample_secret') }

  around do |example|
    Timecop.freeze { example.run }
  end

  describe '#store_dev_info' do
    it "calls the API with auth headers" do
      expected_jwt = Atlassian::Jwt.encode(
        Atlassian::Jwt.build_claims(
          Atlassian::JiraConnect.app_key,
          '/rest/devinfo/0.10/bulk',
          'POST'
        ),
        'sample_secret'
      )

      stub_full_request('https://gitlab-test.atlassian.net/rest/devinfo/0.10/bulk', method: :post)
        .with(
          headers: {
            'Authorization' => "JWT #{expected_jwt}",
            'Content-Type' => 'application/json'
          }
        )

      subject.store_dev_info(project: create(:project))
    end
  end
end
