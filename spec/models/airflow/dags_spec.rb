# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Airflow::Dags, feature_category: :dataops do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:dag_name) }
    it { is_expected.to validate_length_of(:dag_name).is_at_most(255) }
    it { is_expected.to validate_length_of(:schedule).is_at_most(255) }
    it { is_expected.to validate_length_of(:fileloc).is_at_most(255) }
  end
end
