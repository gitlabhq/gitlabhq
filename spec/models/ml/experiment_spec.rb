# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Experiment, feature_category: :mlops do
  let_it_be(:exp) { create(:ml_experiments) }
  let_it_be(:exp2) { create(:ml_experiments, project: exp.project) }

  let(:iid) { exp.iid }
  let(:exp_name) { exp.name }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:candidates) }
    it { is_expected.to have_many(:metadata) }
  end

  describe '.package_name' do
    describe '.package_name' do
      it { expect(exp.package_name).to eq("ml_experiment_#{exp.iid}") }
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

  describe '#by_project_id' do
    let(:project_id) { exp.project_id }

    subject { described_class.by_project_id(project_id) }

    it { is_expected.to match_array([exp, exp2]) }

    context 'when project does not have experiment' do
      let(:project_id) { non_existing_record_iid }

      it { is_expected.to be_empty }
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
end
