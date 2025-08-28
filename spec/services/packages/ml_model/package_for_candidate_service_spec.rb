# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MlModel::PackageForCandidateService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:model) { create(:ml_models, user: project.owner, project: project) }
  let_it_be(:model_version) { create(:ml_model_versions, :with_package, model: model, version: '0.1.0') }
  let_it_be(:model_version_candidate) { model_version.candidate }
  let_it_be(:model_candidate) do
    create(:ml_candidates, user: project.owner, project: project, experiment: model.default_experiment)
  end

  let_it_be(:model_candidate_with_package) do
    create(:ml_candidates, experiment: model.default_experiment, user: project.owner, project: project).tap do |c|
      c.package = create(:ml_model_package, project: project, name: c.package_name, version: c.package_version)
    end
  end

  let_it_be(:not_model_candidate) { create(:ml_candidates, user: project.owner, project: project) }

  let(:base_params) do
    {
      candidate: candidate
    }
  end

  let(:params) { base_params }

  describe '#execute' do
    subject(:execute_service) { described_class.new(project, user, params).execute }

    context 'when candidate does not have a package' do
      let(:candidate) { model_candidate }

      it 'creates a package' do
        expect { execute_service }.to change { Packages::Package.count }.by(1)

        package = execute_service

        expect(candidate.reload.package).to eq(package)
        expect(package.name).to eq(model.name)
        expect(package.version).to eq("candidate_#{candidate.iid}")
        expect(package.project).to eq(project)
      end
    end

    context 'when candidate already has a package' do
      let(:candidate) { model_candidate_with_package }

      it 'returns the package' do
        expect { execute_service }.not_to change { Packages::Package.count }

        package = execute_service

        expect(package).to eq(candidate.package)
      end
    end

    context 'when candidate is nil' do
      let(:candidate) { nil }

      it { is_expected.to be_nil }
    end

    context 'when candidate belongs to a model version' do
      let(:candidate) { model_version_candidate }

      it 'creates a package' do
        expect { execute_service }.to change { candidate.package }.from(nil)
      end
    end

    context 'when candidate does not belong to a model' do
      let(:candidate) { not_model_candidate }

      it 'creates a package' do
        expect { execute_service }.to change { candidate.package }.from(nil)
      end
    end
  end
end
