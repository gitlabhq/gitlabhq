# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupDeployToken, type: :model do
  let(:group) { create(:group) }
  let(:deploy_token) { create(:deploy_token) }

  subject(:group_deploy_token) { create(:group_deploy_token, group: group, deploy_token: deploy_token) }

  it { is_expected.to belong_to :group }
  it { is_expected.to belong_to :deploy_token }

  it { is_expected.to validate_presence_of :deploy_token }
  it { is_expected.to validate_presence_of :group }
  it { is_expected.to validate_uniqueness_of(:deploy_token_id).scoped_to(:group_id) }
end
