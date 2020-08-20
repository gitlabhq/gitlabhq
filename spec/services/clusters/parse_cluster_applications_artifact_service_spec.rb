# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::ParseClusterApplicationsArtifactService do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }

  before do
    project.add_maintainer(user)
  end

  describe 'RELEASE_NAMES' do
    it 'is included in Cluster application names', :aggregate_failures do
      described_class::RELEASE_NAMES.each do |release_name|
        expect(Clusters::Cluster::APPLICATIONS).to include(release_name)
      end
    end
  end

  describe '.new' do
    let(:job) { build(:ci_build) }

    it 'sets the project and current user', :aggregate_failures do
      service = described_class.new(job, user)

      expect(service.project).to eq(job.project)
      expect(service.current_user).to eq(user)
    end
  end

  describe '#execute' do
    let_it_be(:cluster, reload: true) { create(:cluster, projects: [project]) }
    let_it_be(:deployment, reload: true) { create(:deployment, cluster: cluster) }

    let(:job) { deployment.deployable }
    let(:artifact) { create(:ci_job_artifact, :cluster_applications, job: job) }

    it 'calls Gitlab::Kubernetes::Helm::Parsers::ListV2' do
      expect(Gitlab::Kubernetes::Helm::Parsers::ListV2).to receive(:new).and_call_original

      result = described_class.new(job, user).execute(artifact)

      expect(result[:status]).to eq(:success)
    end

    context 'artifact is not of cluster_applications type' do
      let(:artifact) { create(:ci_job_artifact, :archive) }
      let(:job) { artifact.job }

      it 'raise ArgumentError' do
        expect do
          described_class.new(job, user).execute(artifact)
        end.to raise_error(ArgumentError, 'Artifact is not cluster_applications file type')
      end
    end

    context 'artifact exceeds acceptable size' do
      it 'returns an error' do
        stub_const("#{described_class}::MAX_ACCEPTABLE_ARTIFACT_SIZE", 1.byte)

        result = described_class.new(job, user).execute(artifact)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('Cluster_applications artifact too big. Maximum allowable size: 1 Byte')
      end
    end

    context 'job has no deployment' do
      let(:job) { build(:ci_build) }

      it 'returns an error' do
        result = described_class.new(job, user).execute(artifact)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('No deployment found for this job')
      end
    end

    context 'job has no deployment cluster' do
      let(:deployment) { create(:deployment) }
      let(:job) { deployment.deployable }

      it 'returns an error' do
        result = described_class.new(job, user).execute(artifact)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq('No deployment cluster found for this job')
      end
    end

    context 'blob is empty' do
      let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/helm/helm_list_v2_empty_blob.json.gz")) }
      let(:artifact) { create(:ci_job_artifact, :cluster_applications, job: job, file: file) }

      it 'returns success' do
        result = described_class.new(job, user).execute(artifact)

        expect(result[:status]).to eq(:success)
      end
    end

    context 'job has deployment cluster' do
      context 'current user does not have access to deployment cluster' do
        let(:other_user) { create(:user) }

        it 'returns an error' do
          result = described_class.new(job, other_user).execute(artifact)

          expect(result[:status]).to eq(:error)
          expect(result[:message]).to eq('No deployment cluster found for this job')
        end
      end

      it 'does not affect unpermitted cluster applications' do
        expect(Clusters::ParseClusterApplicationsArtifactService::RELEASE_NAMES).to contain_exactly('cilium')
      end

      Clusters::ParseClusterApplicationsArtifactService::RELEASE_NAMES.each do |release_name|
        context release_name do
          include_examples 'parse cluster applications artifact', release_name
        end
      end
    end
  end
end
