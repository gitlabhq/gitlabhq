# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerProject, feature_category: :runner_core do
  let_it_be(:project) { create(:project) }
  let_it_be(:owner_project) { create(:project) }

  it_behaves_like 'includes Limitable concern' do
    let_it_be(:runner) { create(:ci_runner, :project, projects: [owner_project]) }

    subject { build(:ci_runner_project, project: project, runner: runner) }
  end

  describe 'loose foreign keys' do
    context 'with loose foreign key on projects.id' do
      it_behaves_like 'cleanup by a loose foreign key' do
        let(:parent) { project }
        let!(:runner) { create(:ci_runner, :project, projects: [parent]) }
        let(:model) { runner.runner_projects.first }
      end
    end
  end

  describe 'validations' do
    before_all do
      create(:ci_runner, :project, projects: [owner_project])
    end

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of :runner }
    it { is_expected.to validate_uniqueness_of(:runner_id).scoped_to(:project_id) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:runner) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'scopes' do
    describe '.belonging_to_project' do
      let(:other_project) { create(:project) }

      it 'returns the project runner join record' do
        # own
        own_runner = create(:ci_runner, :project, projects: [owner_project])

        # other
        create(:ci_runner, :project, projects: [other_project])

        expect(described_class.belonging_to_project(owner_project.id)).to eq own_runner.runner_projects
      end
    end
  end

  describe '.existing_project_ids' do
    subject(:existing_project_ids) { described_class.existing_project_ids(project_ids) }

    before_all do
      create(:ci_runner, :project, projects: [owner_project, project])
    end

    context 'with only existing project_ids' do
      let(:project_ids) { [project.id, owner_project.id] }

      it { is_expected.to contain_exactly(project.id, owner_project.id) }
    end

    context 'with both existing and non existing project_ids' do
      let(:project_ids) { [project.id, owner_project.id, non_existing_record_id] }

      it { is_expected.to contain_exactly(project.id, owner_project.id) }
    end

    context 'with only non existing project_ids' do
      let(:project_ids) { [non_existing_record_id, non_existing_record_id - 1] }

      it { is_expected.to be_empty }
    end

    context 'with an empty array' do
      let(:project_ids) { [] }

      it { is_expected.to be_empty }
    end
  end
end
