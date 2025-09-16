# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobDefinitionInstance, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:job) { create(:ci_build, :without_job_definition, project: project) }
  let_it_be(:job_definition) { create(:ci_job_definition, project: project) }

  let_it_be(:definition_instance) do
    create(:ci_job_definition_instance,
      job: job, job_definition: job_definition, project: project)
  end

  subject { definition_instance }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) do
      create(:ci_job_definition_instance,
        job: create(:ci_build, :without_job_definition, project: project),
        job_definition: job_definition,
        project: project
      )
    end

    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:job) }
    it { is_expected.to belong_to(:job_definition) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:job) }
    it { is_expected.to validate_presence_of(:job_definition) }
    it { is_expected.to validate_presence_of(:project) }
  end
end
