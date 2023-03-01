# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FogbugzImport::Importer do
  let(:project) { create(:project_empty_repo) }
  let(:fogbugz_project) { { 'ixProject' => project.id, 'sProject' => 'vim' } }
  let(:import_data) { { 'repo' => fogbugz_project } }
  let(:base_url) { 'https://testing.fogbugz.com' }
  let(:token) { 'token' }
  let(:credentials) { { 'fb_session' => { 'uri' => base_url, 'token' => token } } }

  let(:closed_bug) do
    {
      fOpen: 'false',
      sTitle: 'Closed bug',
      sLatestTextSummary: "",
      dtOpened: Time.now.to_s,
      dtLastUpdated: Time.now.to_s,
      events: { event: [] }
    }.with_indifferent_access
  end

  let(:opened_bug) do
    {
      fOpen: 'true',
      sTitle: 'Opened bug',
      sLatestTextSummary: "",
      dtOpened: Time.now.to_s,
      dtLastUpdated: Time.now.to_s,
      events: { event: [] }
    }.with_indifferent_access
  end

  let(:fogbugz_bugs) { [opened_bug, closed_bug] }

  subject(:importer) { described_class.new(project) }

  before do
    project.create_import_data(data: import_data, credentials: credentials)

    stub_fogbugz('listProjects', projects: { project: [fogbugz_project], count: 1 })
    stub_fogbugz('listCategories', categories: { category: [], count: 0 })
    stub_fogbugz('search', cases: { case: fogbugz_bugs, count: fogbugz_bugs.size })
  end

  it 'imports bugs' do
    expect { subject.execute }.to change { Issue.count }.by(2)
  end

  it 'imports opened bugs' do
    subject.execute

    issue = Issue.where(project_id: project.id).find_by_title(opened_bug[:sTitle])

    expect(issue.state_id).to eq(Issue.available_states[:opened])
  end

  it 'imports closed bugs' do
    subject.execute

    issue = Issue.where(project_id: project.id).find_by_title(closed_bug[:sTitle])

    expect(issue.state_id).to eq(Issue.available_states[:closed])
  end

  context 'verify url' do
    context 'when host is localhost' do
      let(:base_url) { 'https://localhost:3000' }

      it 'does not allow localhost requests' do
        expect { subject.execute }
          .to raise_error(
            ::Gitlab::HTTP::BlockedUrlError,
            "URL is blocked: Requests to localhost are not allowed"
          )
      end
    end

    context 'when host is on local network' do
      let(:base_url) { 'http://192.168.0.1' }

      it 'does not allow localhost requests' do
        expect { subject.execute }
          .to raise_error(
            ::Gitlab::HTTP::BlockedUrlError,
            "URL is blocked: Requests to the local network are not allowed"
          )
      end
    end

    context 'when host is ftp protocol' do
      let(:base_url) { 'ftp://testing' }

      it 'only accept http and https requests' do
        expect { subject.execute }
          .to raise_error(
            HTTParty::UnsupportedURIScheme,
            "'ftp://testing/api.asp' Must be HTTP, HTTPS or Generic"
          )
      end
    end
  end

  def stub_fogbugz(command, response)
    stub_request(:post, "#{base_url}/api.asp")
      .with(body: hash_including({ 'cmd' => command, 'token' => token }))
      .to_return(status: 200, body: response.to_xml(root: :response))
  end
end
