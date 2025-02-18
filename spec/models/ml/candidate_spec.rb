# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Candidate, factory_default: :keep, feature_category: :mlops do
  let_it_be(:candidate) { create(:ml_candidates, :with_metrics_and_params, :with_artifact, name: 'candidate0') }
  let_it_be(:candidate_with_generic) { create(:ml_candidates, :with_generic_package, name: 'run1') }
  let_it_be(:candidate_with_no_package) { create(:ml_candidates, name: 'run2') }
  let_it_be(:candidate2) do
    create(:ml_candidates, experiment: candidate.experiment, name: 'candidate2', project: candidate.project)
  end

  let_it_be(:existing_model) { create(:ml_models, project: candidate2.project) }
  let_it_be(:existing_model_version) do
    create(:ml_model_versions, model: existing_model, candidate: candidate2)
  end

  let_it_be(:candidate_for_model) do
    create(:ml_candidates, experiment: existing_model.default_experiment, project: existing_model.project)
  end

  let(:project) { candidate.project }

  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:ci_build).class_name('Ci::Build') }
    it { is_expected.to belong_to(:model_version).class_name('Ml::ModelVersion') }
    it { is_expected.to have_many(:params) }
    it { is_expected.to have_many(:metrics) }
    it { is_expected.to have_many(:metadata) }
  end

  describe 'modules' do
    it_behaves_like 'AtomicInternalId' do
      let(:internal_id_attribute) { :internal_id }
      let(:instance) { build(:ml_candidates, experiment: candidate.experiment) }
      let(:scope) { :project }
      let(:scope_attrs) { { project: instance.project } }
      let(:usage) { :ml_candidates }
    end
  end

  describe 'default values' do
    it { expect(described_class.new.eid).to be_present }
  end

  describe 'validation' do
    let_it_be(:model) { create(:ml_models, project: candidate.project) }
    let_it_be(:model_version1) { create(:ml_model_versions, model: model, candidate: nil) }
    let_it_be(:model_version2) { create(:ml_model_versions, model: model, candidate: nil) }
    let_it_be(:validation_candidate) do
      create(:ml_candidates, model_version: model_version1, project: candidate.project)
    end

    let(:params) do
      {
        model_version: nil
      }
    end

    subject(:errors) do
      candidate = described_class.new(**params)
      candidate.validate
      candidate.errors
    end

    describe 'project' do
      context 'when project is nil' do
        it { expect(errors).to include(:project) }
      end

      context 'when project is valid' do
        let(:params) { { project: candidate.project } }

        it { expect(errors).not_to include(:project) }
      end
    end

    describe 'model_version' do
      context 'when model_version is nil' do
        it { expect(errors).not_to include(:model_version_id) }
      end

      context 'when no other candidate is associated to the model_version' do
        let(:params) { { model_version: model_version2 } }

        it { expect(errors).not_to include(:model_version_id) }
      end

      context 'when another candidate has model_version_id' do
        let(:params) { { model_version: validation_candidate.model_version } }

        it { expect(errors).to include(:model_version_id) }
      end
    end
  end

  describe '.destroy' do
    let_it_be(:candidate_to_destroy) do
      create(:ml_candidates, :with_metrics_and_params, :with_metadata, :with_artifact)
    end

    it 'destroys metrics, params and metadata, but not the artifact', :aggregate_failures do
      expect { candidate_to_destroy.destroy! }
        .to change { Ml::CandidateMetadata.count }.by(-2)
        .and change { Ml::CandidateParam.count }.by(-2)
        .and change { Ml::CandidateMetric.count }.by(-2)
        .and not_change { Packages::Package.count }
    end

    context 'when candidate is associated to a model version' do
      let(:candidate_to_destroy) { candidate2 }

      it 'does not destroy the candidate' do
        expect { candidate_to_destroy.destroy! }.to raise_error(ActiveRecord::ActiveRecordError)
        expect(candidate_to_destroy.errors.full_messages).to include('Cannot delete a candidate associated ' \
          'to a model version')
      end
    end
  end

  describe '.artifact_root' do
    let(:tested_candidate) { candidate }

    subject { tested_candidate.artifact_root }

    it { is_expected.to eq("/#{candidate.package_name}/candidate_#{candidate.iid}/") }

    context 'when candidate belongs to model' do
      let(:tested_candidate) { candidate_for_model }

      it do
        is_expected.to eq("/#{existing_model.name}/candidate_#{tested_candidate.iid}/")
      end
    end
  end

  describe '.package_version' do
    let(:tested_candidate) { candidate }

    subject { tested_candidate.package_version }

    it { is_expected.to eq("candidate_#{candidate.iid}") }

    context 'for candidates with legacy generic package' do
      let(:tested_candidate) { candidate_with_generic }

      it { is_expected.to eq(candidate_with_generic.iid) }
    end

    context 'for candidates with no package' do
      let(:tested_candidate) { candidate_with_no_package }

      it { is_expected.to eq("candidate_#{candidate_with_no_package.iid}") }
    end
  end

  describe '.for_model?' do
    subject { tested_candidate.for_model? }

    context 'when candidate is not for a model experiment' do
      let(:tested_candidate) { candidate }

      it { is_expected.to eq(false) }
    end

    context 'when candidate belongs to model version' do
      let(:tested_candidate) { candidate2 }

      it { is_expected.to eq(false) }
    end

    context 'when candidate belongs to model but not to model version' do
      let(:tested_candidate) { candidate_for_model }

      it { is_expected.to eq(true) }
    end
  end

  describe '.eid' do
    let_it_be(:eid) { SecureRandom.uuid }

    let_it_be(:candidate3) do
      build(:ml_candidates, :with_metrics_and_params, name: 'candidate0', eid: eid)
    end

    subject { candidate3.eid }

    it { is_expected.to eq(eid) }
  end

  describe '.artifact' do
    let(:tested_candidate) { candidate }

    subject { tested_candidate.artifact }

    context 'when has logged artifacts' do
      it 'returns the package' do
        expect(subject.name).to eq(tested_candidate.package_name)
      end
    end

    context 'when does not have logged artifacts' do
      let(:tested_candidate) { candidate2 }

      it { is_expected.to be_nil }
    end
  end

  describe '#by_project_id_and_eid' do
    let(:project_id) { candidate.experiment.project_id }
    let(:eid) { candidate.eid }

    subject { described_class.with_project_id_and_eid(project_id, eid) }

    context 'when eid exists', 'and belongs to project' do
      it { is_expected.to eq(candidate) }
    end

    context 'when eid exists', 'and does not belong to project' do
      let(:project_id) { non_existing_record_id }

      it { is_expected.to be_nil }
    end

    context 'when eid does not exist' do
      let(:eid) { 'a' }

      it { is_expected.to be_nil }
    end
  end

  describe '#by_project_id_and_iid' do
    let(:project_id) { candidate.experiment.project_id }
    let(:iid) { candidate.iid }

    subject { described_class.with_project_id_and_iid(project_id, iid) }

    context 'when internal_id exists', 'and belongs to project' do
      it { is_expected.to eq(candidate) }
    end

    context 'when internal_id exists', 'and does not belong to project' do
      let(:project_id) { non_existing_record_id }

      it { is_expected.to be_nil }
    end

    context 'when internal_id does not exist' do
      let(:iid) { non_existing_record_id }

      it { is_expected.to be_nil }
    end
  end

  describe '#with_project_id_and_id' do
    let(:project_id) { candidate.experiment.project_id }
    let(:id) { candidate.id }

    subject { described_class.with_project_id_and_id(project_id, id) }

    context 'when internal_id exists', 'and belongs to project' do
      it { is_expected.to eq(candidate) }
    end

    context 'when id exists and does not belong to project' do
      let(:project_id) { non_existing_record_id }

      it { is_expected.to be_nil }
    end

    context 'when id does not exist' do
      let(:id) { non_existing_record_id }

      it { is_expected.to be_nil }
    end
  end

  describe "#latest_metrics" do
    let_it_be(:candidate3) { create(:ml_candidates, experiment: candidate.experiment) }
    let_it_be(:metric1) { create(:ml_candidate_metrics, candidate: candidate3) }
    let_it_be(:metric2) { create(:ml_candidate_metrics, candidate: candidate3) }
    let_it_be(:metric3) { create(:ml_candidate_metrics, name: metric1.name, candidate: candidate3) }

    subject { candidate3.latest_metrics }

    it 'fetches only the last metric for the name' do
      expect(subject).to match_array([metric2, metric3])
    end
  end

  describe "#including_relationships" do
    subject { described_class.including_relationships.find_by(id: candidate.id) }

    it 'loads latest metrics and params', :aggregate_failures do
      expect(subject.association_cached?(:latest_metrics)).to be(true)
      expect(subject.association_cached?(:params)).to be(true)
      expect(subject.association_cached?(:user)).to be(true)
      expect(subject.association_cached?(:project)).to be(true)
      expect(subject.association_cached?(:package)).to be(true)
      expect(subject.association_cached?(:ci_build)).to be(true)
    end
  end

  describe '#by_name' do
    let(:name) { candidate.name }

    subject { described_class.by_name(name) }

    context 'when name matches' do
      it 'gets the correct candidates' do
        expect(subject).to match_array([candidate])
      end
    end

    context 'when name matches partially' do
      let(:name) { 'andidate' }

      it 'gets the correct candidates' do
        expect(subject).to match_array([candidate, candidate2])
      end
    end

    context 'when name does not match' do
      let(:name) { non_existing_record_id.to_s }

      it 'does not fetch any candidate' do
        expect(subject).to be_empty
      end
    end
  end

  describe '#without_model_version' do
    subject { described_class.without_model_version }

    it 'finds only candidates without model version' do
      expect(subject).to match_array([candidate, candidate_for_model, candidate_with_no_package,
        candidate_with_generic])
    end
  end

  describe 'from_ci?' do
    subject { candidate }

    it 'is false if candidate does not have ci_build_id' do
      allow(candidate).to receive(:ci_build_id).and_return(nil)

      is_expected.not_to be_from_ci
    end

    it 'is true if candidate does has ci_build_id' do
      allow(candidate).to receive(:ci_build_id).and_return(1)

      is_expected.to be_from_ci
    end
  end

  describe '#order_by_metric' do
    let_it_be(:auc_metrics) do
      create(:ml_candidate_metrics, name: 'auc', value: 0.4, candidate: candidate)
      create(:ml_candidate_metrics, name: 'auc', value: 0.8, candidate: candidate2)
    end

    let(:direction) { 'desc' }

    subject { described_class.order_by_metric('auc', direction) }

    it 'orders correctly' do
      expect(subject).to eq([candidate2, candidate])
    end

    context 'when direction is asc' do
      let(:direction) { 'asc' }

      it 'orders correctly' do
        expect(subject).to eq([candidate, candidate2])
      end
    end
  end

  context 'with loose foreign key on ml_candidates.ci_build_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let_it_be(:parent) { create(:ci_build) }
      let_it_be(:model) { create(:ml_candidates, ci_build: parent) }
    end
  end
end
