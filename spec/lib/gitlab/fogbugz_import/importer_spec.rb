# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::FogbugzImport::Importer do
  let(:project) { create(:project_empty_repo) }
  let(:fogbugz_project) { { 'ixProject' => project.id, 'sProject' => 'vim' } }
  let(:import_data) { { 'repo' => fogbugz_project } }
  let(:base_url) { 'https://testing.fogbugz.com' }
  let(:token) { 'token' }
  let(:credentials) { { 'fb_session' => { 'uri' => base_url, 'token' => token } } }

  let(:bug_fopen) { 'false' }
  let(:bug_events) { [] }
  let(:bug) do
    {
      fOpen: bug_fopen,
      sTitle: 'Bug title',
      sLatestTextSummary: "",
      dtOpened: Time.now.to_s,
      dtLastUpdated: Time.now.to_s,
      events: { event: bug_events }
    }.with_indifferent_access
  end

  let(:fogbugz_bugs) { [bug] }

  subject(:importer) { described_class.new(project) }

  before do
    project.create_import_data(data: import_data, credentials: credentials)

    stub_fogbugz('listProjects', projects: { project: [fogbugz_project], count: 1 })
    stub_fogbugz('listCategories', categories: { category: [], count: 0 })
    stub_fogbugz('search', cases: { case: fogbugz_bugs, count: fogbugz_bugs.size })
  end

  it 'imports the bug', :aggregate_failures do
    expect { subject.execute }.to change { Issue.count }.by(1)

    issue = Issue.where(project_id: project.id).find_by_title(bug[:sTitle])

    expect(issue.state_id).to eq(Issue.available_states[:closed])
  end

  context 'when importing an opened bug' do
    let(:bug_fopen) { 'true' }

    it 'imports the bug' do
      expect { subject.execute }.to change { Issue.count }.by(1)

      issue = Issue.where(project_id: project.id).find_by_title(bug[:sTitle])

      expect(issue.state_id).to eq(Issue.available_states[:opened])
    end
  end

  context 'when importing multiple bugs' do
    let(:fogbugz_bugs) { [bug, bug] }

    it 'imports the bugs' do
      expect { subject.execute }.to change { Issue.count }.by(2)
    end
  end

  context 'when imported bug contains events' do
    let(:event_time) { Time.now.to_s }
    let(:bug_events) do
      [
        { sVerb: 'Opened', s: 'First event', dt: event_time },
        { sVerb: 'Assigned', s: 'Second event', dt: event_time }
      ]
    end

    let(:expected_note_timestamp) { DateTime.parse(event_time) }

    it 'imports the correct event', :aggregate_failures do
      expect { subject.execute }.to change { Note.count }.by(1)

      note = Note.where(project_id: project.id).last

      expect(note).to have_attributes(
        note: "*By  on #{expected_note_timestamp} (imported from FogBugz)*\n\n---\n\n#{bug_events[1][:s]}",
        created_at: expected_note_timestamp,
        updated_at: expected_note_timestamp
      )
    end
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
