# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::ModelVersion, feature_category: :mlops do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:base_project) { create(:project) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:model) }
    it { is_expected.to belong_to(:package) }
  end

  describe 'validation' do
    let_it_be(:valid_version) { 'valid_version' }
    let_it_be(:model) { create(:ml_models, project: base_project) }
    let_it_be(:valid_package) do
      build_stubbed(:ml_model_package, project: base_project, version: valid_version, name: model.name)
    end

    let(:package) { valid_package }
    let(:version) { valid_version }

    subject(:errors) do
      mv = described_class.new(version: version, model: model, package: package, project: model.project)
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
          create(:ml_model_versions, model: model)
        end

        let(:version) { existing_model_version.version }

        it { expect(errors).to include(:version) }
      end
    end

    describe 'model' do
      context 'when project is different' do
        before do
          allow(model).to receive(:project_id).and_return(non_existing_record_id)
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

      context 'when package is not ml_model' do
        let(:package) do
          build_stubbed(:generic_package, project: base_project, name: model.name, version: valid_version)
        end

        it { expect(errors[:package]).to include('package must be ml_model') }
      end
    end
  end
end
