# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::MlModel::FindOrCreatePackageService, feature_category: :mlops do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.creator }
  let_it_be(:ci_build) { create(:ci_build, :running, user: user, project: project) }

  let(:base_params) do
    {
      name: 'mymodel',
      version: '0.0.1'
    }
  end

  let(:params) { base_params }

  describe '#execute' do
    subject(:execute_service) { described_class.new(project, user, params).execute }

    context 'when model does not exist' do
      it 'creates the model' do
        expect { subject }.to change { project.packages.ml_model.count }.by(1)

        package = project.packages.ml_model.last

        aggregate_failures do
          expect(package.creator).to eq(user)
          expect(package.package_type).to eq('ml_model')
          expect(package.name).to eq('mymodel')
          expect(package.version).to eq('0.0.1')
          expect(package.build_infos.count).to eq(0)
        end
      end

      context 'when build is provided' do
        let(:params) { base_params.merge(build: ci_build) }

        it 'creates package and package build info' do
          expect { subject }.to change { project.packages.ml_model.count }.by(1)

          package = project.packages.ml_model.last

          aggregate_failures do
            expect(package.creator).to eq(user)
            expect(package.package_type).to eq('ml_model')
            expect(package.name).to eq('mymodel')
            expect(package.version).to eq('0.0.1')
            expect(package.build_infos.first.pipeline).to eq(ci_build.pipeline)
          end
        end
      end
    end

    context 'when model already exists' do
      it 'does not create a new model', :aggregate_failures do
        model = project.packages.ml_model.create!(params)

        expect do
          new_model = subject
          expect(new_model).to eq(model)
        end.not_to change { project.packages.ml_model.count }
      end
    end
  end
end
