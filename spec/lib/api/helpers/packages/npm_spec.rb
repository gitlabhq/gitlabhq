# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::Packages::Npm, feature_category: :package_registry do  # rubocop: disable RSpec/FilePath
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { group }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:package) { create(:npm_package, project: project) }

  let(:package_name) { package.name }
  let(:params) { { id: project.id } }
  let(:endpoint_scope) { :project }
  let(:object) { klass.new(params) }
  let(:klass) do
    Struct.new(:params) do
      include ::API::Helpers
      include ::API::Helpers::Packages::Npm
    end
  end

  before do
    allow(object).to receive(:endpoint_scope).and_return(endpoint_scope)
    allow(object).to receive(:current_user).and_return(user)
  end

  describe '#finder_for_endpoint_scope' do
    subject { object.finder_for_endpoint_scope(package_name) }

    context 'when called with project scope' do
      it 'returns a PackageFinder for project scope' do
        expect(::Packages::Npm::PackageFinder).to receive(:new).with(package_name, project: project)

        subject
      end
    end

    context 'when called with instance scope' do
      let(:params) { { package_name: package_name } }
      let(:endpoint_scope) { :instance }

      it 'returns a PackageFinder for namespace scope' do
        expect(::Packages::Npm::PackageFinder).to receive(:new).with(package_name, namespace: group)

        subject
      end
    end

    context 'when called with group scope' do
      let(:params) { { id: group.id } }
      let(:endpoint_scope) { :group }

      it 'returns a PackageFinder for group scope' do
        expect(::Packages::Npm::PackageFinder).to receive(:new).with(package_name, namespace: group)

        subject
      end
    end
  end

  describe '#project_id_or_nil' do
    subject { object.project_id_or_nil }

    context 'when called with project scope' do
      let(:params) { { id: project.id } }
      let(:endpoint_scope) { :project }

      it { is_expected.to eq(project.id) }
    end

    context 'when called with group scope' do
      let(:params) { { id: group.id, package_name: package.name } }
      let(:endpoint_scope) { :group }

      it { is_expected.to eq(project.id) }
    end

    context 'when called with instance scope' do
      let(:endpoint_scope) { :instance }

      context 'when given an unscoped name' do
        let(:params) { { package_name: 'foo' } }

        it { is_expected.to eq(nil) }
      end

      context 'when given a scope that does not match a group name' do
        let(:params) { { package_name: '@nonexistent-group/foo' } }

        it { is_expected.to eq(nil) }
      end

      context 'when given a scope that matches a group name' do
        let(:params) { { package_name: package.name } }

        it { is_expected.to eq(project.id) }

        context 'with another package with the same name, in another project in the namespace' do
          let_it_be(:project2) { create(:project, :public, namespace: namespace) }
          let_it_be(:package2) { create(:npm_package, name: package.name, project: project2) }

          it 'returns the project id for the newest matching package within the scope' do
            expect(subject).to eq(project2.id)
          end
        end
      end

      context 'with npm_allow_packages_in_multiple_projects disabled' do
        before do
          stub_feature_flags(npm_allow_packages_in_multiple_projects: false)
        end

        context 'when given an unscoped name' do
          let(:params) { { package_name: 'foo' } }

          it { is_expected.to eq(nil) }
        end

        context 'when given a scope that does not match a group name' do
          let(:params) { { package_name: '@nonexistent-group/foo' } }

          it { is_expected.to eq(nil) }
        end

        context 'when given a scope that matches a group name' do
          let(:params) { { package_name: package.name } }

          it { is_expected.to eq(project.id) }

          context 'with another package with the same name, in another project in the namespace' do
            let_it_be(:project2) { create(:project, :public, namespace: namespace) }
            let_it_be(:package2) { create(:npm_package, name: package.name, project: project2) }

            it 'returns the project id for the newest matching package within the scope' do
              expect(subject).to eq(project2.id)
            end
          end
        end
      end
    end
  end

  describe '#enqueue_sync_metadata_cache_worker' do
    it_behaves_like 'enqueue a worker to sync a metadata cache' do
      subject { object.enqueue_sync_metadata_cache_worker(project, package_name) }
    end
  end
end
