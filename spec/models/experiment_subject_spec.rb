# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExperimentSubject, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:namespace) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:experiment) }

    describe 'must_have_one_subject_present' do
      let(:experiment_subject) { build(:experiment_subject, user: nil, namespace: nil, project: nil) }
      let(:error_message) { 'Must have exactly one of User, Namespace, or Project.' }

      it 'fails when no subject is present' do
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end

      it 'passes when user subject is present' do
        experiment_subject.user = build(:user)
        expect(experiment_subject).to be_valid
      end

      it 'passes when namespace subject is present' do
        experiment_subject.namespace = build(:group)
        expect(experiment_subject).to be_valid
      end

      it 'passes when project subject is present' do
        experiment_subject.project = build(:project)
        expect(experiment_subject).to be_valid
      end

      it 'fails when more than one subject is present', :aggregate_failures do
        # two subjects
        experiment_subject.user = build(:user)
        experiment_subject.namespace = build(:group)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)

        # three subjects
        experiment_subject.project = build(:project)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end
    end
  end

  describe '.valid_subject?' do
    subject(:valid_subject?) { described_class.valid_subject?(subject_class.new) }

    context 'when passing a Group, Namespace, User or Project' do
      [Group, Namespace, User, Project].each do |subject_class|
        let(:subject_class) { subject_class }

        it { is_expected.to be(true) }
      end
    end

    context 'when passing another object' do
      let(:subject_class) { Issue }

      it { is_expected.to be(false) }
    end
  end
end
