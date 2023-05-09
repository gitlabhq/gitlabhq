# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ml::Candidate, factory_default: :keep, feature_category: :mlops do
  let_it_be(:candidate) { create(:ml_candidates, :with_metrics_and_params, :with_artifact, name: 'candidate0') }
  let_it_be(:candidate2) do
    create(:ml_candidates, experiment: candidate.experiment, user: create(:user), name: 'candidate2')
  end

  let(:project) { candidate.project }

  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:package) }
    it { is_expected.to belong_to(:ci_build).class_name('Ci::Build') }
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
  end

  describe '.artifact_root' do
    subject { candidate.artifact_root }

    it { is_expected.to eq("/#{candidate.package_name}/#{candidate.iid}/") }
  end

  describe '.package_version' do
    subject { candidate.package_version }

    it { is_expected.to eq(candidate.iid) }
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

  describe "#latest_metrics" do
    let_it_be(:candidate3) { create(:ml_candidates, experiment: candidate.experiment) }
    let_it_be(:metric1) { create(:ml_candidate_metrics, candidate: candidate3) }
    let_it_be(:metric2) { create(:ml_candidate_metrics, candidate: candidate3 ) }
    let_it_be(:metric3) { create(:ml_candidate_metrics, name: metric1.name, candidate: candidate3) }

    subject { candidate3.latest_metrics }

    it 'fetches only the last metric for the name' do
      expect(subject).to match_array([metric2, metric3] )
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
        expect(subject).to match_array([])
      end
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
      let!(:parent) { create(:ci_build) }
      let!(:model) { create(:ml_candidates, ci_build: parent) }
    end
  end
end
