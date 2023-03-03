# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::API::Helpers::Packages::Npm, feature_category: :package_registry do  # rubocop: disable RSpec/FilePath
  let(:object) { klass.new(params) }
  let(:klass) do
    Struct.new(:params) do
      include ::API::Helpers
      include ::API::Helpers::Packages::Npm
    end
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { group }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:package) { create(:npm_package, project: project) }

  describe '#endpoint_scope' do
    subject { object.endpoint_scope }

    context 'when params includes an id' do
      let(:params) { { id: 42, package_name: 'foo' } }

      it { is_expected.to eq(:project) }
    end

    context 'when params does not include an id' do
      let(:params) { { package_name: 'foo' } }

      it { is_expected.to eq(:instance) }
    end
  end

  describe '#finder_for_endpoint_scope' do
    subject { object.finder_for_endpoint_scope(package_name) }

    let(:package_name) { package.name }

    context 'when called with project scope' do
      let(:params) { { id: project.id } }

      it 'returns a PackageFinder for project scope' do
        expect(::Packages::Npm::PackageFinder).to receive(:new).with(package_name, project: project)

        subject
      end
    end

    context 'when called with instance scope' do
      let(:params) { { package_name: package_name } }

      it 'returns a PackageFinder for namespace scope' do
        expect(::Packages::Npm::PackageFinder).to receive(:new).with(package_name, namespace: group)

        subject
      end
    end
  end

  describe '#project_id_or_nil' do
    subject { object.project_id_or_nil }

    context 'when called with project scope' do
      let(:params) { { id: project.id } }

      it { is_expected.to eq(project.id) }
    end

    context 'when called with namespace scope' do
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
end
