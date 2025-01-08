# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Experiment, feature_category: :mlops do
  let_it_be(:exp) { create(:ml_experiments) }
  let_it_be(:exp2) { create(:ml_experiments, project: exp.project) }
  let_it_be(:model) { create(:ml_models, project: exp.project) }
  let_it_be(:model_experiment) { model.default_experiment }

  let(:iid) { exp.iid }
  let(:exp_name) { exp.name }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:candidates) }
    it { is_expected.to have_many(:metadata) }
    it { is_expected.to belong_to(:model).class_name('Ml::Model') }
  end

  describe '#destroy' do
    it 'allow experiment without model to be destroyed' do
      experiment = create(:ml_experiments, project: exp.project)

      expect { experiment.destroy! }.to change { Ml::Experiment.count }.by(-1)
    end

    it 'throws error when destroying experiment with model' do
      experiment = create(:ml_models, project: exp.project).default_experiment

      expect { experiment.destroy! }.to raise_error(ActiveRecord::ActiveRecordError)
      expect(experiment.errors.full_messages).to include('Cannot delete an experiment associated to a model')
    end
  end

  describe '.package_name' do
    it { expect(exp.package_name).to eq("ml_experiment_#{exp.iid}") }

    context 'when model belongs to package' do
      it 'is the model name' do
        expect(model_experiment.package_name).to eq(model.name)
      end
    end
  end

  describe '.for_model?' do
    it 'is false if it is not the default experiment for a model' do
      expect(exp.for_model?).to be(false)
    end

    it 'is true if it is not the default experiment for a model' do
      expect(model_experiment.for_model?).to be(true)
    end
  end

  describe '.by_project' do
    subject { described_class.by_project(exp.project) }

    it { is_expected.to match_array([exp, exp2, model_experiment]) }
  end

  describe '.including_project' do
    subject { described_class.including_project }

    it 'loads latest version' do
      expect(subject.first.association_cached?(:project)).to be(true)
    end
  end

  describe '.including_user' do
    subject { described_class.including_user }

    it 'loads latest version' do
      expect(subject.first.association_cached?(:user)).to be(true)
    end
  end

  describe '#by_project_id_and_iid' do
    subject { described_class.by_project_id_and_iid(exp.project_id, iid) }

    context 'if exists' do
      it { is_expected.to eq(exp) }
    end

    context 'if does not exist' do
      let(:iid) { non_existing_record_id }

      it { is_expected.to be(nil) }
    end
  end

  describe '#by_project_id_and_name' do
    subject { described_class.by_project_id_and_name(exp.project_id, exp_name) }

    context 'if exists' do
      it { is_expected.to eq(exp) }
    end

    context 'if does not exist' do
      let(:exp_name) { 'hello' }

      it { is_expected.to be_nil }
    end
  end

  describe '.find_or_create' do
    let(:name) { exp.name }
    let(:project) { exp.project }

    subject(:find_or_create) { described_class.find_or_create(project, name, exp.user) }

    context 'when experiments exists' do
      it 'fetches existing experiment', :aggregate_failures do
        expect { find_or_create }.not_to change { Ml::Experiment.count }

        expect(find_or_create).to eq(exp)
      end
    end

    context 'when experiments does not exist' do
      let(:name) { 'a new experiment' }

      it 'creates the experiment', :aggregate_failures do
        expect { find_or_create }.to change { Ml::Experiment.count }.by(1)

        expect(find_or_create.name).to eq(name)
        expect(find_or_create.user).to eq(exp.user)
        expect(find_or_create.project).to eq(project)
      end
    end

    context 'when experiment name exists but project is different' do
      let(:project) { create(:project) }

      it 'creates a model', :aggregate_failures do
        expect { find_or_create }.to change { Ml::Experiment.count }.by(1)

        expect(find_or_create.name).to eq(name)
        expect(find_or_create.user).to eq(exp.user)
        expect(find_or_create.project).to eq(project)
      end
    end
  end

  describe '#with_candidate_count' do
    let_it_be(:exp3) do
      create(:ml_experiments, project: exp.project).tap do |e|
        create_list(:ml_candidates, 3, experiment: e, user: nil)
        create(:ml_candidates, experiment: exp2, user: nil)
      end
    end

    subject { described_class.with_candidate_count.to_h { |e| [e.id, e.candidate_count] } }

    it 'fetches the candidate count', :aggregate_failures do
      expect(subject[exp.id]).to eq(0)
      expect(subject[exp2.id]).to eq(1)
      expect(subject[exp3.id]).to eq(3)
    end
  end

  describe '#package_for_experiment?' do
    using RSpec::Parameterized::TableSyntax

    subject { described_class.package_for_experiment?(package_name) }

    where(:package_name, :id) do
      'ml_experiment_1234' | true
      'ml_experiment_1234abc' | false
      'ml_experiment_abc' | false
      'ml_experiment_' | false
      'blah' | false
    end

    with_them do
      it { is_expected.to be(id) }
    end
  end

  describe "#exclude_experiments_for_models" do
    subject { described_class.by_project(exp.project).exclude_experiments_for_models }

    it 'excludes experiments that belongs to a model' do
      is_expected.to match_array([exp, exp2])
    end
  end

  describe '.count_for_project' do
    subject { described_class.count_for_project(exp.project_id) }

    it { is_expected.to be(3) }
  end
end
