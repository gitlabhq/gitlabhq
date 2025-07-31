# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::JobDefinition, feature_category: :continuous_integration do
  let_it_be(:project) { create(:project) }
  let_it_be(:job_definition) { create(:ci_job_definition, project: project) }

  subject { job_definition }

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:model) { create(:ci_job_definition, project: project) }
    let!(:parent) { model.project }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
