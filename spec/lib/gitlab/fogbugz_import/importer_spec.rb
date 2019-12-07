# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::FogbugzImport::Importer do
  let(:project) { create(:project_empty_repo) }
  let(:importer) { described_class.new(project) }
  let(:repo) do
    instance_double(Gitlab::FogbugzImport::Repository,
      safe_name: 'vim',
      path: 'vim',
      raw_data: '')
  end
  let(:import_data) { { 'repo' => repo } }
  let(:credentials) do
    {
      'fb_session' => {
        'uri' => 'https://testing.fogbugz.com',
        'token' => 'token'
      }
    }
  end

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

  before do
    project.create_import_data(data: import_data, credentials: credentials)
    allow_any_instance_of(::Fogbugz::Interface).to receive(:command).with(:listCategories).and_return([])
    allow_any_instance_of(Gitlab::FogbugzImport::Client).to receive(:cases).and_return(fogbugz_bugs)
  end

  it 'imports bugs' do
    expect { importer.execute }.to change { Issue.count }.by(2)
  end

  it 'imports opened bugs' do
    importer.execute

    issue = Issue.where(project_id: project.id).find_by_title(opened_bug[:sTitle])

    expect(issue.state_id).to eq(Issue.available_states[:opened])
  end

  it 'imports closed bugs' do
    importer.execute

    issue = Issue.where(project_id: project.id).find_by_title(closed_bug[:sTitle])

    expect(issue.state_id).to eq(Issue.available_states[:closed])
  end
end
