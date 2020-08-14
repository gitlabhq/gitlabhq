# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployKeysGroup do
  describe "Associations" do
    it { is_expected.to belong_to(:group_deploy_key) }
    it { is_expected.to belong_to(:group) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:group_id) }
    it { is_expected.to validate_presence_of(:group_deploy_key) }
  end
end
