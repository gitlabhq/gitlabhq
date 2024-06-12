# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProject, feature_category: :runner do
  it_behaves_like 'includes Limitable concern' do
    let_it_be(:project) { create(:project) }
    let_it_be(:owner_project) { create(:project) }
    let_it_be(:runner) { create(:ci_runner, :project, projects: [owner_project]) }

    subject { build(:ci_runner_project, project: project, runner: runner) }
  end

  context 'loose foreign key on ci_runner_projects.project_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:project) }
      let!(:model) { create(:ci_runner_project, project: parent) }
    end
  end

  describe 'validations' do
    before_all do
      create(:ci_runner, :project, projects: [create(:project)])
    end

    it { is_expected.to validate_presence_of(:project).on([:create, :update]) }
    it { is_expected.to validate_presence_of :runner }
    it { is_expected.to validate_uniqueness_of(:runner_id).scoped_to(:project_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:runner) }
    it { is_expected.to belong_to(:project) }
  end
end
