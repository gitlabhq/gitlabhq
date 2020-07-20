# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agent do
  subject { create(:cluster_agent) }

  it { is_expected.to belong_to(:project).class_name('::Project') }
  it { is_expected.to have_many(:agent_tokens).class_name('Clusters::AgentToken') }

  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_length_of(:name).is_at_most(255) }
  it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id) }
end
