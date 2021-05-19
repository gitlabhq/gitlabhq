# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agent do
  subject { create(:cluster_agent) }

  it { is_expected.to belong_to(:created_by_user).class_name('User').optional }
  it { is_expected.to belong_to(:project).class_name('::Project') }
  it { is_expected.to have_many(:agent_tokens).class_name('Clusters::AgentToken') }
  it { is_expected.to have_many(:last_used_agent_tokens).class_name('Clusters::AgentToken') }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(63) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }

  describe 'scopes' do
    describe '.ordered_by_name' do
      let(:names) { %w(agent-d agent-b agent-a agent-c) }

      subject { described_class.ordered_by_name }

      before do
        names.each do |name|
          create(:cluster_agent, name: name)
        end
      end

      it { expect(subject.map(&:name)).to eq(names.sort) }
    end

    describe '.with_name' do
      let!(:matching_name) { create(:cluster_agent, name: 'matching-name') }
      let!(:other_name) { create(:cluster_agent, name: 'other-name') }

      subject { described_class.with_name(matching_name.name) }

      it { is_expected.to contain_exactly(matching_name) }
    end
  end

  describe 'validation' do
    describe 'name validation' do
      it 'rejects names that do not conform to RFC 1123', :aggregate_failures do
        %w[Agent agentA agentAagain gent- -agent agent.a agent/a agent>a].each do |name|
          agent = build(:cluster_agent, name: name)

          expect(agent).not_to be_valid
          expect(agent.errors[:name]).to eq(["can contain only lowercase letters, digits, and '-', but cannot start or end with '-'"])
        end
      end

      it 'accepts valid names', :aggregate_failures do
        %w[agent agent123 agent-123].each do |name|
          agent = build(:cluster_agent, name: name)

          expect(agent).to be_valid
        end
      end
    end
  end

  describe '#has_access_to?' do
    let(:agent) { build(:cluster_agent) }

    it 'has access to own project' do
      expect(agent.has_access_to?(agent.project)).to be_truthy
    end

    it 'does not have access to other projects' do
      expect(agent.has_access_to?(create(:project))).to be_falsey
    end
  end
end
