# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectCustomAttribute do
  describe 'assocations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    subject { build :project_custom_attribute }

    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:key) }
    it { is_expected.to validate_presence_of(:value) }
    it { is_expected.to validate_uniqueness_of(:key).scoped_to(:project_id) }
  end
end
