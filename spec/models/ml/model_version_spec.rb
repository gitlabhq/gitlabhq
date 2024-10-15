# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersion, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:base_project) { create(:project) }
  let_it_be(:model1) { create(:ml_models, project: base_project) }
  let_it_be(:model2) { create(:ml_models, project: base_project) }

  let_it_be(:model_version1) { create(:ml_model_versions, model: model1, version: '4.0.0') }
  let_it_be(:model_version2) { create(:ml_model_versions, model: model_version1.model, version: '6.0.0') }
  let_it_be(:model_version3) { create(:ml_model_versions, model: model2, version: '5.0.0') }
  let_it_be(:model_version4) { create(:ml_model_versions, model: model_version3.model, version: '4.0.1') }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:model) }
    it { is_expected.to belong_to(:package).class_name('Packages::MlModel::Package') }
    it { is_expected.to have_one(:candidate).class_name('Ml::Candidate') }
    it { is_expected.to have_many(:metadata) }
  end

  describe 'validation' do
    let_it_be(:valid_version) { '1.0.0' }
    let_it_be(:valid_package) do
      build_stubbed(:ml_model_package, project: base_project, version: valid_version, name: model1.name)
    end

    let_it_be(:valid_description) { 'Valid description' }

    let(:package) { valid_package }
    let(:version) { valid_version }
    let(:description) { valid_description }

    subject(:errors) do
      mv = described_class.new(version: version, model: model1, package: package, project: model1.project,
        description: description)
      mv.validate
      mv.errors
    end

    it 'validates a valid model version' do
      expect(errors).to be_empty
    end

    describe 'version' do
      where(:ctx, :version) do
        'can\'t be blank'                         | ''
        'is invalid'                              | '!!()()'
        'is too long (maximum is 255 characters)' | ('a' * 256)
        'must follow semantic version'            | '1'
      end
      with_them do
        it { expect(errors.messages.values.flatten).to include(ctx) }
      end

      context 'when version is not unique in project+name' do
        let_it_be(:existing_model_version) do
          create(:ml_model_versions, model: model1)
        end

        let(:version) { existing_model_version.version }

        it { expect(errors).to include(:version) }
      end
    end

    describe 'description' do
      context 'when description is too large' do
        let(:description) { 'a' * 10_001 }

        it { expect(errors).to include(:description) }
      end

      context 'when description is below threshold' do
        let(:description) { 'a' * 100 }

        it { expect(errors).not_to include(:description) }
      end
    end

    describe 'model' do
      context 'when project is different' do
        before do
          allow(model1).to receive(:project_id).and_return(non_existing_record_id)
        end

        it { expect(errors[:model]).to include('model project must be the same') }
      end
    end

    describe 'package' do
      where(:property, :value, :error_message) do
        :name       | 'another_name'    | 'package name must be the same'
        :version    | 'another_version' | 'package version must be the same'
        :project_id | 0                 | 'package project must be the same'
      end
      with_them do
        before do
          allow(package).to receive(property).and_return(:value)
        end

        it { expect(errors[:package]).to include(error_message) }
      end
    end
  end

  describe '#add_metadata' do
    it 'accepts an array of metadata and persists it to the model version' do
      input = [
        { project_id: base_project.id, key: 'tag1', value: 'value1' },
        { project_id: base_project.id, key: 'tag2', value: 'value2' }
      ]

      expect { model_version1.add_metadata(input) }.to change { model_version1.metadata.count }.by(2)
    end

    it 'raises an error when duplicate key names are supplied' do
      input = [
        { project_id: base_project.id, key: 'tag1', value: 'value1' },
        { project_id: base_project.id, key: 'tag1', value: 'value2' }
      ]

      expect { model_version1.add_metadata(input) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it 'raises an error when validation fails' do
      input = [
        { project_id: base_project.id, key: nil, value: 'value1' }
      ]

      expect { model_version1.add_metadata(input) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe '#find_or_create!' do
    let_it_be(:existing_model_version) { create(:ml_model_versions, model: model1, version: '1.0.0') }

    let(:version) { existing_model_version.version }
    let(:package) { nil }
    let(:description) { 'Some description' }

    subject(:find_or_create) { described_class.find_or_create!(model1, version, package, description) }

    context 'if model version exists' do
      it 'returns the model version', :aggregate_failures do
        expect { find_or_create }.not_to change { Ml::ModelVersion.count }
        is_expected.to eq(existing_model_version)
      end
    end

    context 'if model version does not exist' do
      let(:version) { '2.0.0' }
      let(:package) { create(:ml_model_package, project: model1.project, name: model1.name, version: version) }

      it 'creates another model version', :aggregate_failures do
        expect { find_or_create }.to change { Ml::ModelVersion.count }.by(1)
        model_version = find_or_create

        expect(model_version.version).to eq(version)
        expect(model_version.model).to eq(model1)
        expect(model_version.description).to eq(description)
        expect(model_version.package).to eq(package)
      end
    end
  end

  describe '#by_project_id_and_id' do
    let(:id) { model_version1.id }
    let(:project_id) { model_version1.project.id }

    subject { described_class.by_project_id_and_id(project_id, id) }

    context 'if exists' do
      it { is_expected.to eq(model_version1) }
    end

    context 'if id has no match' do
      let(:id) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end

    context 'if project id does not match' do
      let(:project_id) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end
  end

  describe '.by_project_id_name_and_version' do
    let(:version) { model_version1.version }
    let(:project_id) { model_version1.project.id }
    let(:model_name) { model_version1.model.name }
    let_it_be(:latest_version) { create(:ml_model_versions, model: model_version1.model) }

    subject { described_class.by_project_id_name_and_version(project_id, model_name, version) }

    context 'if exists' do
      it { is_expected.to eq(model_version1) }
    end

    context 'if id has no match' do
      let(:version) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end

    context 'if project id does not match' do
      let(:project_id) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end

    context 'if model name does not match' do
      let(:model_name) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end
  end

  describe '.order_by_model_id_id_desc' do
    subject { described_class.order_by_model_id_id_desc }

    it 'orders by (model_id, id desc)' do
      is_expected.to match_array([model_version2, model_version1, model_version4, model_version3])
    end
  end

  describe '.latest_by_model' do
    subject { described_class.latest_by_model }

    it 'returns only the latest model version per model id' do
      is_expected.to match_array([model_version3, model_version2])
    end
  end

  describe '.including_relations' do
    subject(:scoped) { described_class.including_relations }

    it 'loads latest version', :aggregate_failures do
      expect(scoped.first.association_cached?(:project)).to be(true)
      expect(scoped.first.association_cached?(:model)).to be(true)
    end
  end

  describe '.by_version' do
    subject(:filtered) { described_class.by_version('4.0') }

    it 'returns versions with the prefix' do
      expect(filtered).to contain_exactly(model_version1, model_version4)
    end
  end

  describe '.order_by_version' do
    subject(:ordered) { described_class.order_by_version(order) }

    context 'when order is asc' do
      let(:order) { 'asc' }

      it { is_expected.to match_array([model_version1, model_version4, model_version3, model_version2]) }
    end

    context 'when order is desc' do
      let(:order) { 'desc' }

      it { is_expected.to match_array([model_version2, model_version3, model_version4, model_version1]) }
    end

    context 'when order is invalid' do
      let(:order) { 'invalid' }

      it 'throws error' do
        expect { ordered }.to raise_error(ArgumentError)
      end
    end
  end

  context 'when parsing semver components' do
    let(:model_version) { build(:ml_model_versions, model: model1, version: semver, project: base_project) }

    where(:semver, :valid, :major, :minor, :patch, :prerelease) do
      '1'             | false | nil | nil | nil | nil
      '1.2'           | false | nil | nil | nil | nil
      '1.2.3'         | true  | 1   | 2   | 3   | nil
      '1.2.3-beta'    | true  | 1   | 2   | 3   | 'beta'
      '1.2.3.beta'    | false | nil | nil | nil | nil
    end
    with_them do
      it do
        expect(model_version.semver_major).to be major
        expect(model_version.semver_minor).to be minor
        expect(model_version.semver_patch).to be patch
        expect(model_version.semver_prerelease).to eq prerelease
      end
    end
  end
end
