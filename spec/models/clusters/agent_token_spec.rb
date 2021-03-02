# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentToken do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to validate_length_of(:description).is_at_most(1024) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_presence_of(:name) }

  describe '#token' do
    it 'is generated on save' do
      agent_token = build(:cluster_agent_token, token_encrypted: nil)
      expect(agent_token.token).to be_nil

      agent_token.save!

      expect(agent_token.token).to be_present
    end

    it 'is at least 50 characters' do
      agent_token = create(:cluster_agent_token)
      expect(agent_token.token.length).to be >= 50
    end
  end
end
