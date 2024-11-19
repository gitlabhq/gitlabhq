# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Npm::Metadatum, type: :model, feature_category: :package_registry do
  describe 'relationships' do
    it { is_expected.to belong_to(:package).class_name('Packages::Npm::Package').inverse_of(:npm_metadatum) }

    # TODO: Remove with the rollout of the FF npm_extract_npm_package_model
    # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
    it 'belongs to `legacy_package`' do
      is_expected.to belong_to(:legacy_package).conditions(package_type: :npm).class_name('Packages::Package')
        .inverse_of(:npm_metadatum).with_foreign_key(:package_id)
    end
  end

  describe 'validations' do
    describe 'package', :aggregate_failures do
      it { is_expected.to validate_presence_of(:package) }

      # TODO: Remove with the rollout of the FF npm_extract_npm_package_model
      # https://gitlab.com/gitlab-org/gitlab/-/issues/501469
      it { is_expected.not_to validate_presence_of(:legacy_package) }

      context 'when npm_extract_npm_package_model is disabled' do
        before do
          stub_feature_flags(npm_extract_npm_package_model: false)
        end

        it { is_expected.to validate_presence_of(:legacy_package) }
        it { is_expected.not_to validate_presence_of(:package) }
      end

      describe '#ensure_npm_package_type', :aggregate_failures do
        subject(:npm_metadatum) { build(:npm_metadatum) }

        it 'builds a valid metadatum' do
          expect { npm_metadatum }.not_to raise_error
          expect(npm_metadatum).to be_valid
        end

        context 'with a different package type' do
          let(:package) { build(:package) }

          it 'raises the error' do
            expect { build(:npm_metadatum, package: package) }.to raise_error(ActiveRecord::AssociationTypeMismatch)
          end

          context 'when npm_extract_npm_package_model is disabled' do
            before do
              stub_feature_flags(npm_extract_npm_package_model: false)
            end

            it 'adds the validation error' do
              npm_metadatum = build(:npm_metadatum, legacy_package: package, package: nil)

              expect(npm_metadatum).not_to be_valid
              expect(npm_metadatum.errors.to_a).to include('Package type must be NPM')
            end
          end
        end
      end
    end

    describe 'package_json', :aggregate_failures do
      let(:valid_json) { { 'name' => 'foo', 'version' => 'v1.0', 'dist' => { 'tarball' => 'x', 'shasum' => 'x' } } }

      it { is_expected.to allow_value(valid_json).for(:package_json) }
      it { is_expected.to allow_value(valid_json.merge('extra-field': { foo: 'bar' })).for(:package_json) }
      it { is_expected.to allow_value(with_dist { |dist| dist.merge('extra-field': 'x') }).for(:package_json) }

      %w[name version dist].each do |field|
        it { is_expected.not_to allow_value(valid_json.except(field)).for(:package_json) }
      end

      %w[tarball shasum].each do |field|
        it { is_expected.not_to allow_value(with_dist { |dist| dist.except(field) }).for(:package_json) }
      end

      it { is_expected.not_to allow_value({}).for(:package_json) }

      it {
        is_expected.not_to allow_value(test: 'test' * 10000).for(:package_json).with_message(/structure is too large/)
      }

      def with_dist
        valid_json.tap do |h|
          h['dist'] = yield(h['dist'])
        end
      end
    end
  end

  describe 'scopes' do
    describe '.package_id_in' do
      let_it_be(:package) { create(:npm_package) }
      let_it_be(:metadatum_1) { create(:npm_metadatum, package: package) }
      let_it_be(:metadatum_2) { create(:npm_metadatum) }

      it 'returns metadatums with the given package ids' do
        expect(described_class.package_id_in([package.id])).to contain_exactly(metadatum_1)
      end
    end
  end
end
