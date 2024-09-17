# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Model, feature_category: :mlops do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:existing_model) { create(:ml_models, name: 'an_existing_model', project: project1) }
  let_it_be(:another_existing_model) { create(:ml_models, name: 'an_existing_model', project: project2) }
  let_it_be(:valid_name) { 'a_valid_name' }
  let_it_be(:valid_description) { 'Valid description' }
  let_it_be(:default_experiment) { create(:ml_experiments, name: "[model]#{valid_name}", project: project1) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:default_experiment) }
    it { is_expected.to have_many(:versions) }
    it { is_expected.to have_many(:metadata) }
    it { is_expected.to have_one(:latest_version).class_name('Ml::ModelVersion').inverse_of(:model) }
  end

  describe '#valid?' do
    using RSpec::Parameterized::TableSyntax

    let(:name) { valid_name }

    let(:description) { valid_description }

    subject(:errors) do
      m = described_class.new(name: name, project: project1, default_experiment: default_experiment,
        description: description)
      m.validate
      m.errors
    end

    it 'validates a valid model version' do
      expect(errors).to be_empty
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

    describe 'name' do
      where(:ctx, :name) do
        'name is blank'                     | ''
        'name is not valid package name'    | '!!()()'
        'name is too large'                 | ('a' * 256)
        'name is not unique in the project' | 'an_existing_model'
      end
      with_them do
        it { expect(errors).to include(:name) }
      end
    end

    describe 'default_experiment' do
      context 'when experiment name name is different than model name' do
        before do
          allow(default_experiment).to receive(:name).and_return("#{name}a")
        end

        it { expect(errors).to include(:default_experiment) }
      end

      context 'when model version project is different than model project' do
        before do
          allow(default_experiment).to receive(:project_id).and_return(project1.id + 1)
        end

        it { expect(errors).to include(:default_experiment) }
      end
    end

    describe 'candidates' do
      let_it_be(:candidate1) { create(:ml_model_versions, model: existing_model).candidate }
      let_it_be(:candidate2) do
        create(:ml_candidates, experiment: existing_model.default_experiment, project: project1)
      end

      let_it_be(:candidate3) { create(:ml_candidates, project: project1) }

      it 'returns only the candidates for default experiment that do not belong to a model version' do
        expect(existing_model.candidates).to match_array([candidate2])
      end
    end

    describe '.by_project' do
      subject { described_class.by_project(project1) }

      it { is_expected.to match_array([existing_model]) }
    end

    describe '.including_latest_version' do
      subject { described_class.including_latest_version }

      it 'loads latest version' do
        expect(subject.first.association_cached?(:latest_version)).to be(true)
      end
    end
  end

  describe '.including_project' do
    subject { described_class.including_project }

    it 'loads latest version' do
      expect(subject.first.association_cached?(:project)).to be(true)
    end
  end

  describe 'with_version_count' do
    let(:model) { existing_model }

    subject { described_class.with_version_count.find_by(id: model.id).version_count }

    context 'when model has versions' do
      before do
        create(:ml_model_versions, model: model)
      end

      it { is_expected.to eq(1) }
    end

    context 'when model has no versions' do
      let(:model) { another_existing_model }

      it { is_expected.to eq(0) }
    end
  end

  describe '#by_project_and_id' do
    let(:id) { existing_model.id }
    let(:project_id) { existing_model.project.id }

    subject { described_class.by_project_id_and_id(project_id, id) }

    context 'if exists' do
      it { is_expected.to eq(existing_model) }
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

  describe '#all_packages' do
    it 'returns an empty array when no model versions exist' do
      expect(existing_model.all_packages).to eq([])
    end

    it 'returns one package when a single model version exists' do
      version = create(:ml_model_versions, :with_package, model: existing_model)

      all_packages = existing_model.all_packages
      expect(all_packages.length).to be(1)
      expect(all_packages.first).to eq(version.package)
    end

    it 'returns multiple packages when multiple model versions exist' do
      version1 = create(:ml_model_versions, :with_package, model: existing_model)
      version2 = create(:ml_model_versions, :with_package, model: existing_model)

      all_packages = existing_model.all_packages
      expect(all_packages.length).to be(2)
      expect(all_packages).to match_array([version1.package, version2.package])
    end
  end

  describe '.prefixed_experiment' do
    it 'returns the given string prefixed with "[model]"' do
      expect(described_class.prefixed_experiment('a_valid_name')).to eq('[model]a_valid_name')
    end
  end
end
