# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExperimentSubject, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:experiment) }
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:group) }
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:experiment) }

    describe 'must_have_one_subject_present' do
      let(:experiment_subject) { build(:experiment_subject, user: nil, group: nil, project: nil) }
      let(:error_message) { 'Must have exactly one of User, Group, or Project.' }

      it 'fails when no subject is present' do
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end

      it 'passes when user subject is present' do
        experiment_subject.user = build(:user)
        expect(experiment_subject).to be_valid
      end

      it 'passes when group subject is present' do
        experiment_subject.group = build(:group)
        expect(experiment_subject).to be_valid
      end

      it 'passes when project subject is present' do
        experiment_subject.project = build(:project)
        expect(experiment_subject).to be_valid
      end

      it 'fails when more than one subject is present', :aggregate_failures do
        # two subjects
        experiment_subject.user = build(:user)
        experiment_subject.group = build(:group)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)

        # three subjects
        experiment_subject.project = build(:project)
        expect(experiment_subject).not_to be_valid
        expect(experiment_subject.errors[:base]).to include(error_message)
      end
    end
  end
end
