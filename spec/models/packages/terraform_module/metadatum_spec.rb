# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::TerraformModule::Metadatum, type: :model, feature_category: :package_registry do
  it { is_expected.to be_a(SemanticVersionable) }

  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'default values' do
    it { is_expected.to have_attributes(fields: {}) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:project) }

    describe '#metadata' do
      let_it_be(:metadata_fields) do
        {
          readme: 'README',
          inputs: [{ name: 'foo', description: 'input desc', type: 'string' }],
          outputs: [{ name: 'foo', description: 'output desc' }],
          dependencies: { providers: [{ name: 'foo', source: 'gitlab', version: '1.0.0' }],
                          modules: [{ name: 'bar', source: 'terraform', version: '1.2.3' }] },
          resources: %w[aws.gitlab_runner_instance aws_autoscaling_hook.terminate_instances]
        }
      end

      it 'validates #fields against the terraform_module_metadata schema', :aggregate_failures do
        is_expected.to allow_value(root: { readme: 'README' }).for(:fields)
        is_expected.to allow_value(
          root: metadata_fields,
          submodules: { submodule: metadata_fields }
        ).for(:fields)
        is_expected.to allow_value(
          root: metadata_fields,
          submodules: { submodule: metadata_fields },
          examples: { example: metadata_fields.except(:dependencies, :resources) }
        ).for(:fields)
        is_expected.to allow_value({}).for(:fields)
        is_expected.not_to allow_value(root: { readme: 1 }).for(:fields)
        is_expected.not_to allow_value(root: { readme: 'README' }, submodules: [{ readme: 'README' }]).for(:fields)
        is_expected.not_to allow_value(root: { readme: 'README' * described_class::MAX_FIELDS_SIZE }).for(:fields)
                   .with_message(/metadata is too large/)
      end
    end

    describe '#terraform_module_package_type' do
      subject(:metadatum) { build(:terraform_module_metadatum) }

      it 'builds a valid metadatum' do
        expect { metadatum }.not_to raise_error
        expect(metadatum).to be_valid
      end

      context 'with a different package type' do
        let(:package) { build(:generic_package) }

        it 'raises the error' do
          expect do
            build(:terraform_module_metadatum, package: package)
          end.to raise_error(ActiveRecord::AssociationTypeMismatch)
        end
      end
    end

    describe 'semver validation' do
      using RSpec::Parameterized::TableSyntax

      where(:version, :valid, :semver_major, :semver_minor, :semver_patch, :semver_prerelease) do
        '1'          | false | nil | nil | nil | nil
        '1.2'        | false | nil | nil | nil | nil
        '1.2.3'      | true  | 1   | 2   | 3   | nil
        '1.2.3-beta' | true  | 1   | 2   | 3   | 'beta'
        '1.2.3.beta' | false | nil | nil | nil | nil
      end

      with_them do
        let(:metadatum) { build(:terraform_module_metadatum, semver: version) }

        it 'validates the semver' do
          if valid
            expect(metadatum).to be_valid.and have_attributes(
              semver_major: semver_major,
              semver_minor: semver_minor,
              semver_patch: semver_patch,
              semver_prerelease: semver_prerelease
            )
          else
            expect(metadatum).not_to be_valid
          end
        end
      end

      context 'for semver_patch_convert_to_bigint' do
        let(:metadatum) { create(:terraform_module_metadatum, semver: '1.2.3') }

        subject do
          metadatum.connection.execute(<<~SQL)
            SELECT semver_patch_convert_to_bigint FROM packages_terraform_module_metadata WHERE package_id = #{metadatum.package_id}
          SQL
          .first['semver_patch_convert_to_bigint']
        end

        it { is_expected.to eq(metadatum.semver_patch) }
      end
    end

    context 'when the parent project is destroyed' do
      let_it_be(:metadatum) { create(:terraform_module_metadatum) }

      it 'destroys the metadatum' do
        expect { metadatum.project.destroy! }.to change { described_class.count }.by(-1)
      end
    end
  end
end
