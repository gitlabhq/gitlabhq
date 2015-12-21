require 'spec_helper'

describe Gitlab::BitbucketImport::Client, lib: true do
  let(:token) { '123456' }
  let(:secret) { 'secret' }
  let(:client) { Gitlab::BitbucketImport::Client.new(token, secret) }

  before do
    Gitlab.config.omniauth.providers << OpenStruct.new(app_id: "asd123", app_secret: "asd123", name: "bitbucket")
  end

  it 'all OAuth client options are symbols' do
    client.consumer.options.keys.each do |key|
      expect(key).to be_kind_of(Symbol)
    end
  end

  context 'issues' do
    let(:per_page) { 50 }
    let(:count) { 95 }
    let(:sample_issues) do
      issues = []

      count.times do |i|
        issues << { local_id: i }
      end

      issues
    end
    let(:first_sample_data) { { count: count, issues: sample_issues[0..per_page - 1] } }
    let(:second_sample_data) { { count: count, issues: sample_issues[per_page..count] } }
    let(:project_id) { 'namespace/repo' }

    it 'retrieves issues over a number of pages' do
      stub_request(:get,
                   "https://bitbucket.org/api/1.0/repositories/#{project_id}/issues?limit=50&sort=utc_created_on&start=0").
          to_return(status: 200,
                    body: first_sample_data.to_json,
                    headers: {})

      stub_request(:get,
                   "https://bitbucket.org/api/1.0/repositories/#{project_id}/issues?limit=50&sort=utc_created_on&start=50").
          to_return(status: 200,
                    body: second_sample_data.to_json,
                    headers: {})

      issues = client.issues(project_id)
      expect(issues.count).to eq(95)
    end
  end
end
