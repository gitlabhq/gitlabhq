# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::Job, feature_category: :environment_management do
  it { is_expected.to belong_to(:environment).required }
  it { is_expected.to belong_to(:project).required }
  it { is_expected.to belong_to(:pipeline).with_foreign_key(:ci_pipeline_id).required }
  it { is_expected.to belong_to(:job).with_foreign_key(:ci_job_id).required }
  it { is_expected.to belong_to(:deployment).optional }

  describe 'validations' do
    let_it_be(:job_environment) { create(:job_environment) }

    subject { job_environment }

    it { is_expected.to validate_uniqueness_of(:ci_job_id).scoped_to(:environment_id) }

    it { is_expected.to validate_presence_of(:expanded_environment_name) }
    it { is_expected.to validate_length_of(:expanded_environment_name).is_at_most(255) }
    it { is_expected.to allow_value('valid-environment-name').for(:expanded_environment_name) }
    it { is_expected.not_to allow_value('/invalid/environment/name').for(:expanded_environment_name) }
  end
end
