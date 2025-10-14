# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Composer::Package, feature_category: :package_registry do
  subject(:composer_package) { build(:composer_package) }

  describe 'validations' do
    describe '#valid_composer_global_name' do
      let_it_be(:package) { create(:composer_package) }
      let_it_be(:project) { build_stubbed(:project) }

      context 'with different name and different project' do
        let(:new_package) { build(:composer_package, name: 'different_name', project: project) }

        it { expect(new_package).to be_valid }
      end

      context 'with same name and different project' do
        let(:new_package) { build(:composer_package, name: package.name, project: project) }

        it 'does not validate second package' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Name is already taken by another project')
        end

        context 'with pending destruction package' do
          let_it_be(:package) { create(:composer_package, :pending_destruction) }

          it { expect(new_package).to be_valid }
        end
      end
    end

    describe '.with_composer_target' do
      let_it_be(:sha) { OpenSSL::Digest.hexdigest('SHA256', 'foo') }
      let_it_be(:package1) { create(:composer_package, target_sha: sha) }
      let_it_be(:package2) { create(:composer_package, target_sha: sha) }
      let_it_be(:package3) { create(:composer_package, target_sha: OpenSSL::Digest.hexdigest('SHA256', 'bar')) }

      subject(:result) { described_class.with_composer_target(sha) }

      it 'selects packages with the specified sha' do
        expect(result).to contain_exactly(package1, package2)
      end
    end

    describe '#version' do
      it_behaves_like 'validating version to be SemVer compliant for', :composer_package
    end

    describe '#name' do
      it { is_expected.to validate_uniqueness_of(:name).scoped_to(:project_id, :version) }

      context 'for project id, name and version uniqueness' do
        let_it_be_with_reload(:package) { create(:composer_package) }

        let_it_be(:new_package) do
          build(:composer_package, project: package.project, name: package.name, version: package.version)
        end

        it 'does not allow a package with same project, name and version' do
          expect(new_package).not_to be_valid
          expect(new_package.errors.to_a).to include('Name has already been taken')
        end

        context 'with pending_destruction package' do
          before_all do
            package.pending_destruction!
          end

          it 'allows a package with same project, name and version' do
            expect(new_package).to be_valid
          end
        end
      end

      it_behaves_like 'validate package name format', :composer_package
    end
  end

  describe '.installable' do
    it_behaves_like 'installable packages', :composer_package
  end

  describe '#package_type' do
    it 'behaves as enum', :aggregate_failures do
      expect(composer_package.package_type).to eq('composer')
      expect(composer_package.composer?).to be_truthy
    end
  end
end
