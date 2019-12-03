# frozen_string_literal: true

require 'spec_helper'

describe ClusterBasicEntity do
  describe '#as_json' do
    subject { described_class.new(cluster, request: request).as_json }

    let(:maintainer) { create(:user) }
    let(:developer) { create(:user) }
    let(:current_user) { maintainer }
    let(:request) { double(:request, current_user: current_user) }
    let(:project) { create(:project) }
    let(:cluster) { create(:cluster, name: 'the-cluster', projects: [project]) }

    before do
      project.add_maintainer(maintainer)
      project.add_developer(developer)
    end

    it 'matches cluster_basic entity schema' do
      expect(subject.as_json).to match_schema('cluster_basic')
    end

    it 'exposes the cluster details' do
      expect(subject[:name]).to eq('the-cluster')
      expect(subject[:path]).to eq("/#{project.full_path}/-/clusters/#{cluster.id}")
    end

    context 'when the user does not have permission to view the cluster' do
      let(:current_user) { developer }

      it 'does not include the path' do
        expect(subject[:path]).to be_nil
      end
    end
  end
end
