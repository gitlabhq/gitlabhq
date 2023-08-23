# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersion, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:base_project) { create(:project) }
  let_it_be(:model1) { create(:ml_models, project: base_project) }
  let_it_be(:model2) { create(:ml_models, project: base_project) }

  let_it_be(:model_version1) { create(:ml_model_versions, model: model1) }
  let_it_be(:model_version2) { create(:ml_model_versions, model: model_version1.model) }
  let_it_be(:model_version3) { create(:ml_model_versions, model: model2) }
  let_it_be(:model_version4) { create(:ml_model_versions, model: model_version3.model) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:model) }
    it { is_expected.to belong_to(:package).class_name('Packages::MlModel::Package') }
  end

  describe 'validation' do
    let_it_be(:valid_version) { '1.0.0' }
    let_it_be(:valid_package) do
      build_stubbed(:ml_model_package, project: base_project, version: valid_version, name: model1.name)
    end

    let(:package) { valid_package }
    let(:version) { valid_version }

    subject(:errors) do
      mv = described_class.new(version: version, model: model1, package: package, project: model1.project)
      mv.validate
      mv.errors
    end

    it 'validates a valid model version' do
      expect(errors).to be_empty
    end

    describe 'version' do
      where(:ctx, :version) do
        'version is blank'                     | ''
        'version is not valid package version' | '!!()()'
        'version is too large'                 | ('a' * 256)
      end
      with_them do
        it { expect(errors).to include(:version) }
      end

      context 'when version is not unique in project+name' do
        let_it_be(:existing_model_version) do
          create(:ml_model_versions, model: model1)
        end

        let(:version) { existing_model_version.version }

        it { expect(errors).to include(:version) }
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

  describe '#find_or_create!' do
    let_it_be(:existing_model_version) { create(:ml_model_versions, model: model1, version: '1.0.0') }

    let(:version) { existing_model_version.version }
    let(:package) { nil }

    subject(:find_or_create) { described_class.find_or_create!(model1, version, package) }

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
        expect(model_version.package).to eq(package)
      end
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
      is_expected.to match_array([model_version4, model_version2])
    end
  end
end
