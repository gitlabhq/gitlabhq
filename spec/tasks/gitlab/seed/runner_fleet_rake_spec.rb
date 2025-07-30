# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:seed:runner_fleet rake task', :silence_stdout, feature_category: :fleet_visibility do
  let(:registration_prefix) { 'rf-' }
  let(:runner_count) { 10 }
  let(:job_count) { 20 }
  let(:task_params) { [username, registration_prefix, runner_count, job_count] }
  let(:runner_releases_url) do
    ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url
  end

  before do
    Rake.application.rake_require('tasks/gitlab/seed/runner_fleet')

    WebMock.stub_request(:get, runner_releases_url).to_return(
      body: '[]',
      status: 200,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  subject(:rake_task) { run_rake_task('gitlab:seed:runner_fleet', task_params) }

  context 'with admin username', :enable_admin_mode do
    let(:username) { 'runner_fleet_seed' }
    let!(:admin) { create(:user, :admin, username: username) }

    it 'performs runner fleet seed successfully' do
      expect { rake_task }
        .to change { Group.count }.by(6)
        .and change { Project.count }.by(3)
        .and change { Ci::Runner.count }.by(runner_count)
        .and change { Ci::Runner.instance_type.count }.by(1)
        .and change { Ci::Build.count }.by(job_count)

      expect(Group.search(registration_prefix).count).to eq 6
      expect(Project.search(registration_prefix).count).to eq 3
      expect(Ci::Runner.search(registration_prefix).count).to eq runner_count
    end
  end
end
