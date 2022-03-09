# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnassignRunnerService, '#execute' do
  subject(:service) { described_class.new(runner_project, user).execute }

  let_it_be(:runner) { create(:ci_runner, :project, projects: [project]) }
  let_it_be(:project) { create(:project) }

  let(:runner_project) { runner.runner_projects.last }

  context 'without user' do
    let(:user) { nil }

    it 'does not destroy runner_project', :aggregate_failures do
      expect(runner_project).not_to receive(:destroy)
      expect { service }.not_to change { runner.runner_projects.count }.from(1)

      is_expected.to eq(false)
    end
  end

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call destroy on runner_project' do
      expect(runner).not_to receive(:destroy)

      service
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:user, :admin) }

    it 'destroys runner_project' do
      expect(runner_project).to receive(:destroy).once

      service
    end
  end
end
