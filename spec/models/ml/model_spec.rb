# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Model, feature_category: :mlops do
  let_it_be(:project1) { create(:project) }
  let_it_be(:project2) { create(:project) }
  let_it_be(:existing_model) { create(:ml_models, name: 'an_existing_model', project: project1) }
  let_it_be(:another_existing_model) { create(:ml_models, name: 'an_existing_model', project: project2) }
  let_it_be(:valid_name) { 'a_valid_name' }
  let_it_be(:default_experiment) { create(:ml_experiments, name: valid_name, project: project1) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_one(:default_experiment) }
    it { is_expected.to have_many(:versions) }
    it { is_expected.to have_one(:latest_version).class_name('Ml::ModelVersion').inverse_of(:model) }
  end

  describe '#valid?' do
    using RSpec::Parameterized::TableSyntax

    let(:name) { valid_name }

    subject(:errors) do
      m = described_class.new(name: name, project: project1, default_experiment: default_experiment)
      m.validate
      m.errors
    end

    it 'validates a valid model version' do
      expect(errors).to be_empty
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

  describe '.find_or_create' do
    subject(:find_or_create) { described_class.find_or_create(project, name, experiment) }

    let(:name) { existing_model.name }
    let(:project) { existing_model.project }
    let(:experiment) { default_experiment }

    context 'when model name does not exist in the project' do
      let(:name) { 'new_model' }
      let(:experiment) { build(:ml_experiments, name: name, project: project) }

      it 'creates a model', :aggregate_failures do
        expect { find_or_create }.to change { Ml::Model.count }.by(1)

        expect(find_or_create.name).to eq(name)
        expect(find_or_create.project).to eq(project)
        expect(find_or_create.default_experiment).to eq(experiment)
      end
    end

    context 'when model name exists but project is different' do
      let(:project) { create(:project) }
      let(:experiment) { build(:ml_experiments, name: name, project: project) }

      it 'creates a model', :aggregate_failures do
        expect { find_or_create }.to change { Ml::Model.count }.by(1)

        expect(find_or_create.name).to eq(name)
        expect(find_or_create.project).to eq(project)
        expect(find_or_create.default_experiment).to eq(experiment)
      end
    end

    context 'when model exists' do
      it 'fetches existing model', :aggregate_failures do
        expect { find_or_create }.not_to change { Ml::Model.count }

        expect(find_or_create).to eq(existing_model)
      end
    end
  end
end
