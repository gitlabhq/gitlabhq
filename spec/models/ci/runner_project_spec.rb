# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProject do
  it_behaves_like 'includes Limitable concern' do
    subject { build(:ci_runner_project, project: create(:project), runner: create(:ci_runner, :project)) }
  end

  context 'loose foreign key on ci_runner_projects.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_runner_project, project: parent) }
    end
  end
end
