# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::Package, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to have_one(:npm_metadatum).inverse_of(:package) }
  end

  describe 'validations' do
    describe '#name' do
      subject { build_stubbed(:npm_package) }

      it 'allows accepted values' do
        is_expected.to allow_values('@group-1/package', '@any-scope/package', 'unscoped-package').for(:name)
      end

      it 'does not allow unaccepted values' do
        is_expected.not_to allow_values('@inv@lid-scope/package', '@scope/../../package', '@scope%2e%2e%fpackage',
          '@scope/sub/package').for(:name)
      end
    end

    describe '#version' do
      it_behaves_like 'validating version to be SemVer compliant for', :npm_package
    end
  end

  describe '.with_npm_scope' do
    let_it_be(:package1) { create(:npm_package, name: '@test/foobar') }
    let_it_be(:package2) { create(:npm_package, name: '@test2/foobar') }
    let_it_be(:package3) { create(:npm_package, name: 'foobar') }

    subject { described_class.with_npm_scope('test') }

    it { is_expected.to contain_exactly(package1) }
  end

  describe '#sync_npm_metadata_cache' do
    let_it_be(:package) { build_stubbed(:npm_package) }

    it 'enqueues a sync worker job' do
      expect(::Packages::Npm::CreateMetadataCacheWorker)
        .to receive(:perform_async).with(package.project_id, package.name)

      package.sync_npm_metadata_cache
    end
  end

  describe '#npm_package_already_taken' do
    context 'with maven package' do
      let!(:package) { create(:maven_package) }

      it 'allows a package of the same name' do
        new_package = build(:maven_package, name: package.name)

        expect(new_package).to be_valid
      end
    end

    context 'with npm package' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, namespace: group) }
      let_it_be(:second_project) { create(:project, namespace: group) }

      let(:package) { build(:npm_package, project: project, name: name) }

      shared_examples 'validating the first package' do
        it 'validates the first package' do
          expect(package).to be_valid
        end
      end

      shared_examples 'validating the second package' do
        it 'validates the second package' do
          package.save!

          expect(second_package).to be_valid
        end
      end

      shared_examples 'not validating the second package' do |field_with_error:|
        it 'does not validate the second package' do
          package.save!

          expect(second_package).not_to be_valid
          case field_with_error
          when :base
            expect(second_package.errors.messages[:base]).to eq ['Package already exists']
          when :name
            expect(second_package.errors.messages[:name]).to eq ['has already been taken']
          else
            raise ArgumentError, "field #{field_with_error} not expected"
          end
        end
      end

      shared_examples 'validating both if the first package is pending destruction' do
        before do
          package.status = :pending_destruction
        end

        it_behaves_like 'validating the first package'
        it_behaves_like 'validating the second package'
      end

      context 'when following the naming convention' do
        let(:name) { "@#{group.path}/test" }

        context 'with the second package in the project of the first package' do
          let(:second_package) do
            build(:npm_package, project: project, name: second_package_name, version: second_package_version)
          end

          context 'with no duplicated name' do
            let(:second_package_name) { "@#{group.path}/test2" }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicated name' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicate name and duplicated version' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { package.version }

            it_behaves_like 'validating the first package'
            it_behaves_like 'not validating the second package', field_with_error: :name
            it_behaves_like 'validating both if the first package is pending destruction'
          end
        end

        context 'with the second package in a different project than the first package' do
          let(:second_package) do
            build(:npm_package, project: second_project, name: second_package_name, version: second_package_version)
          end

          context 'with no duplicated name' do
            let(:second_package_name) { "@#{group.path}/test2" }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicated name' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicate name and duplicated version' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { package.version }

            it_behaves_like 'validating the first package'
            it_behaves_like 'not validating the second package', field_with_error: :base
            it_behaves_like 'validating both if the first package is pending destruction'
          end
        end
      end

      context 'when not following the naming convention' do
        let(:name) { '@foobar/test' }

        context 'with the second package in the project of the first package' do
          let(:second_package) do
            build(:npm_package, project: project, name: second_package_name, version: second_package_version)
          end

          context 'with no duplicated name' do
            let(:second_package_name) { "@foobar/test2" }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicated name' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicate name and duplicated version' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { package.version }

            it_behaves_like 'validating the first package'
            it_behaves_like 'not validating the second package', field_with_error: :name
            it_behaves_like 'validating both if the first package is pending destruction'
          end
        end

        context 'with the second package in a different project than the first package' do
          let(:second_package) do
            build(:npm_package, project: second_project, name: second_package_name, version: second_package_version)
          end

          context 'with no duplicated name' do
            let(:second_package_name) { "@foobar/test2" }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicated name' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { '5.0.0' }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
          end

          context 'with duplicate name and duplicated version' do
            let(:second_package_name) { package.name }
            let(:second_package_version) { package.version }

            it_behaves_like 'validating the first package'
            it_behaves_like 'validating the second package'
            it_behaves_like 'validating both if the first package is pending destruction'
          end
        end
      end
    end
  end
end
