# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Maven::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Maven::Package') }

    # TODO: Remove with the rollout of the FF maven_extract_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
    it 'belongs to `legacy_package`' do
      is_expected.to belong_to(:legacy_package).conditions(package_type: :maven).class_name('Packages::Package')
        .with_foreign_key(:package_id)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }

    # TODO: Remove with the rollout of the FF maven_extract_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/502402
    it { is_expected.not_to validate_presence_of(:legacy_package) }

    context 'when maven_extract_package_model is disabled' do
      before do
        stub_feature_flags(maven_extract_package_model: false)
      end

      it { is_expected.to validate_presence_of(:legacy_package) }
      it { is_expected.not_to validate_presence_of(:package) }
    end

    describe '#app_name' do
      it { is_expected.to allow_value("my-app").for(:app_name) }
      it { is_expected.not_to allow_value("my/app").for(:app_name) }
      it { is_expected.not_to allow_value("my(app)").for(:app_name) }
    end

    describe '#app_group' do
      it { is_expected.to allow_value("my.domain.com").for(:app_group) }
      it { is_expected.not_to allow_value("my/domain/com").for(:app_group) }
      it { is_expected.not_to allow_value("my(domain)").for(:app_group) }
    end

    describe '#path' do
      it { is_expected.to allow_value("my/domain/com/my-app").for(:path) }
      it { is_expected.to allow_value("my/domain/com/my-app/1.0-SNAPSHOT").for(:path) }
      it { is_expected.not_to allow_value("my(domain)com.my-app").for(:path) }
    end

    describe '#maven_package_type', :aggregate_failures do
      subject(:maven_metadatum) { build(:maven_metadatum) }

      it 'builds a valid metadatum' do
        expect { maven_metadatum }.not_to raise_error
        expect(maven_metadatum).to be_valid
      end

      context 'with a different package type' do
        let(:package) { build(:npm_package) }

        it 'raises the error' do
          expect { build(:maven_metadatum, package: package) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
        end

        context 'when maven_extract_package_model is disabled' do
          before do
            stub_feature_flags(maven_extract_package_model: false)
          end

          it 'adds the validation error' do
            maven_metadatum = build(:maven_metadatum, legacy_package: package, package: nil)

            expect(maven_metadatum).not_to be_valid
            expect(maven_metadatum.errors.to_a).to include('Package type must be Maven')
          end
        end
      end
    end

    context 'with a package' do
      let_it_be(:package) { create(:maven_package, maven_metadatum: nil, package_files: []) }

      describe '.for_package_ids' do
        let_it_be(:metadata) { create_list(:maven_metadatum, 3, package: package) }

        subject { described_class.for_package_ids(package.id) }

        it { is_expected.to match_array(metadata) }
      end

      describe '.order_created' do
        let_it_be(:metadatum1) { create(:maven_metadatum, package: package) }
        let_it_be(:metadatum2) { create(:maven_metadatum, package: package) }
        let_it_be(:metadatum3) { create(:maven_metadatum, package: package) }
        let_it_be(:metadatum4) { create(:maven_metadatum, package: package) }

        subject { described_class.for_package_ids(package.id).order_created }

        it { is_expected.to eq([metadatum1, metadatum2, metadatum3, metadatum4]) }
      end

      describe '.pluck_app_name' do
        let_it_be(:metadatum1) { create(:maven_metadatum, package: package, app_name: 'one') }
        let_it_be(:metadatum2) { create(:maven_metadatum, package: package, app_name: 'two') }
        let_it_be(:metadatum3) { create(:maven_metadatum, package: package, app_name: 'three') }

        subject { described_class.for_package_ids(package.id).pluck_app_name }

        it { is_expected.to match_array([metadatum1, metadatum2, metadatum3].map(&:app_name)) }
      end

      describe '.with_path' do
        let_it_be(:metadatum1) { create(:maven_metadatum, package: package, path: 'one') }
        let_it_be(:metadatum2) { create(:maven_metadatum, package: package, path: 'two') }
        let_it_be(:metadatum3) { create(:maven_metadatum, package: package, path: 'three') }

        subject { described_class.with_path('two') }

        it { is_expected.to match_array([metadatum2]) }
      end
    end
  end
end
