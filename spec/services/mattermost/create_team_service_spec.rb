# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mattermost::CreateTeamService, feature_category: :integrations do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  subject { described_class.new(group, user) }

  it 'creates a team' do
    expect_next_instance_of(::Mattermost::Team) do |instance|
      expect(instance).to receive(:create).with(name: anything, display_name: anything, type: anything)
    end

    subject.execute
  end

  it 'adds an error if a team could not be created' do
    expect_next_instance_of(::Mattermost::Team) do |instance|
      expect(instance).to receive(:create).and_raise(::Mattermost::ClientError, 'client error')
    end

    subject.execute

    expect(group.errors).to be_present
  end
end
