# frozen_string_literal: true

require 'spec_helper'

PROJECT_IDS = [
  278964,
  46678122,
  250833,
  4456656,
  7764,
  74823,
  20699,
  34675721,
  2009901,
  1794617,
  7071551,
  5261717,
  734943,
  430285
].freeze

RSpec.describe 'gitlab:populate_job_traces rake task', :silence_stdout, feature_category: :continuous_integration do
  let!(:project) { create(:project) }

  before do
    Rake.application.rake_require 'tasks/gitlab/populate_job_traces'
  end

  describe "#start_populate" do
    before do
      create_list(:ci_build, 14, :failed, project: project)

      stub_all_job_requests
      stub_all_trace_requests
      stub_const("NUMBER_OF_GITLAB_TRACES", 1)
      stub_const("DEFAULT_NUMBER_OF_TRACES", 1)
    end

    it "populates the job traces" do
      run_rake_task('gitlab:populate_job_traces:populate', project.id, "fake-access-token")

      collection_of_all_traces = +""

      project.builds.each do |job|
        collection_of_all_traces << job.trace.raw
      end

      trace_project_ids = collection_of_all_traces.scan(/\d+/).map(&:to_i).to_set
      project_id_set = PROJECT_IDS.to_set

      expect(project_id_set.subset?(trace_project_ids)).to be_truthy
    end
  end

  describe "with custom project preferences" do
    before do
      create(:ci_build, :failed, project: project)

      stub_job_request("https://gitlab.com/api/v4/projects/999/jobs?order_by=id&pagination=keyset&per_page=100&scope[]=failed&sort=desc")
      stub_trace_request(999)
    end

    it 'populates custom jobs if provided project and number' do
      run_rake_task('gitlab:populate_job_traces:populate', project.id, "fake-access-token", 999, 1)

      expect(project.builds.first.trace.raw).to include("999")
    end
  end

  def stub_all_job_requests
    base_url = "https://gitlab.com/api/v4/projects/%s/jobs?order_by=id&pagination=keyset&per_page=100&scope[]=failed&sort=desc"

    PROJECT_IDS.each do |project_id|
      stub_job_request(format(base_url, project_id))
    end
  end

  def stub_job_request(url)
    stub_request(:get, url)
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Private-Token' => 'fake-access-token',
        'User-Agent' => 'Ruby'
      })
    .to_return(status: 200, body: [{ id: 101 }].to_json, headers: { 'Content-Type' => 'application/json' })
  end

  def stub_all_trace_requests
    PROJECT_IDS.each do |project_id|
      stub_trace_request(project_id)
    end
  end

  def stub_trace_request(project_id)
    base_url = "https://gitlab.com/api/v4/projects/%s/jobs/101/trace"

    stub_request(:get, format(base_url, project_id))
    .with(
      headers: {
        'Accept' => '*/*',
        'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
        'Private-Token' => 'fake-access-token',
        'User-Agent' => 'Ruby'
      })
    .to_return(status: 200, body: "Raw trace body #{project_id}", headers: {})
  end
end
