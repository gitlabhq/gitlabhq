# frozen_string_literal: true

require 'spec_helper'

describe GroupDeployKey do
  it { is_expected.to validate_presence_of(:user) }

  it 'is of type DeployKey' do
    expect(build(:group_deploy_key).type).to eq('DeployKey')
  end
end
