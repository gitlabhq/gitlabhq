# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::AgentMigration, feature_category: :deployment_management do
  it { is_expected.to belong_to(:cluster).class_name('Clusters::Cluster').required }
  it { is_expected.to belong_to(:project).class_name('::Project').required }
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:issue).class_name('::Issue').optional }

  it_behaves_like 'having unique enum values'

  describe 'validations' do
    subject { create(:cluster_agent_migration) }

    it { is_expected.to validate_uniqueness_of(:cluster) }
    it { is_expected.to validate_length_of(:agent_install_message).is_at_most(255) }
  end
end
