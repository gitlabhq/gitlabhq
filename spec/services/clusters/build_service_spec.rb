# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::BuildService, feature_category: :deployment_management do
  describe '#execute' do
    subject { described_class.new(cluster_subject).execute }

    describe 'when cluster subject is a project' do
      let(:cluster_subject) { build(:project) }

      it 'sets the cluster_type to project_type' do
        is_expected.to be_project_type
      end
    end

    describe 'when cluster subject is a group' do
      let(:cluster_subject) { build(:group) }

      it 'sets the cluster_type to group_type' do
        is_expected.to be_group_type
      end
    end

    describe 'when cluster subject is an instance' do
      let(:cluster_subject) { Clusters::Instance.new }

      it 'sets the cluster_type to instance_type' do
        is_expected.to be_instance_type
      end
    end
  end
end
