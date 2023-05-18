# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Generic::FindOrCreatePackageService, feature_category: :package_registry do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be(:ci_build) { create(:ci_build, :running, user: user) }

  let(:params) do
    {
      name: 'mypackage',
      version: '0.0.1'
    }
  end

  describe '#execute' do
    context 'when packages does not exist yet' do
      it 'creates package' do
        service = described_class.new(project, user, params)

        expect { service.execute }.to change { project.packages.generic.count }.by(1)

        package = project.packages.generic.last

        aggregate_failures do
          expect(package.creator).to eq(user)
          expect(package.name).to eq('mypackage')
          expect(package.version).to eq('0.0.1')
          expect(package.last_build_info).to be_nil
        end
      end

      it 'creates package and package build info when build is provided' do
        service = described_class.new(project, user, params.merge(build: ci_build))

        expect { service.execute }.to change { project.packages.generic.count }.by(1)

        package = project.packages.generic.last

        aggregate_failures do
          expect(package.creator).to eq(user)
          expect(package.name).to eq('mypackage')
          expect(package.version).to eq('0.0.1')
          expect(package.last_build_info.pipeline).to eq(ci_build.pipeline)
        end
      end
    end

    context 'when packages already exists' do
      let!(:package) { project.packages.generic.create!(params) }

      context 'when package was created manually' do
        it 'finds the package and does not create package build info even if build is provided' do
          service = described_class.new(project, user, params.merge(build: ci_build))

          expect do
            found_package = service.execute

            expect(found_package).to eq(package)
          end.not_to change { project.packages.generic.count }

          expect(package.reload.last_build_info).to be_nil
        end
      end

      context 'when package was created by pipeline' do
        let(:pipeline) { create(:ci_pipeline, project: project) }

        before do
          package.build_infos.create!(pipeline: pipeline)
        end

        it 'finds the package and does not change package build info even if build is provided' do
          service = described_class.new(project, user, params.merge(build: ci_build))

          expect do
            found_package = service.execute

            expect(found_package).to eq(package)
          end.not_to change { project.packages.generic.count }

          expect(package.reload.last_build_info.pipeline).to eq(pipeline)
        end
      end

      context 'when a pending_destruction package exists', :aggregate_failures do
        let!(:package) { project.packages.generic.create!(params.merge(status: :pending_destruction)) }

        it 'creates a new package' do
          service = described_class.new(project, user, params)

          expect { service.execute }.to change { project.packages.generic.count }.by(1)

          package = project.packages.generic.last

          expect(package.creator).to eq(user)
          expect(package.name).to eq('mypackage')
          expect(package.version).to eq('0.0.1')
          expect(package.last_build_info).to be_nil
        end
      end
    end
  end
end
