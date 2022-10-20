# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experiment do
  subject { build(:experiment) }

  describe 'associations' do
    it { is_expected.to have_many(:experiment_subjects) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe '#record_conversion_event_for_subject' do
    let_it_be(:user) { create(:user) }
    let_it_be(:experiment) { create(:experiment) }
    let_it_be(:context) { { a: 42 } }

    subject(:record_conversion) { experiment.record_conversion_event_for_subject(user, context) }

    context 'when no existing experiment_subject record exists for the given user' do
      it 'does not update or create an experiment_subject record' do
        expect { record_conversion }.not_to change { ExperimentSubject.all.to_a }
      end
    end

    context 'when an existing experiment_subject exists for the given user' do
      context 'but it has already been converted' do
        let(:experiment_subject) { create(:experiment_subject, experiment: experiment, user: user, converted_at: 2.days.ago) }

        it 'does not update the converted_at value' do
          expect { record_conversion }.not_to change { experiment_subject.converted_at }
        end
      end

      context 'and it has not yet been converted' do
        let(:experiment_subject) { create(:experiment_subject, experiment: experiment, user: user) }

        it 'updates the converted_at value' do
          expect { record_conversion }.to change { experiment_subject.reload.converted_at }
        end
      end

      context 'with no existing context' do
        let(:experiment_subject) { create(:experiment_subject, experiment: experiment, user: user) }

        it 'updates the context' do
          expect { record_conversion }.to change { experiment_subject.reload.context }.to('a' => 42)
        end
      end

      context 'with an existing context' do
        let(:experiment_subject) { create(:experiment_subject, experiment: experiment, user: user, converted_at: 2.days.ago, context: { b: 1 } ) }

        it 'merges the context' do
          expect { record_conversion }.to change { experiment_subject.reload.context }.to('a' => 42, 'b' => 1)
        end
      end
    end
  end

  describe '#record_subject_and_variant!' do
    let_it_be(:subject_to_record) { create(:group) }
    let_it_be(:variant) { :control }
    let_it_be(:experiment) { create(:experiment) }

    subject(:record_subject_and_variant!) { experiment.record_subject_and_variant!(subject_to_record, variant) }

    context 'when no existing experiment_subject record exists for the given subject' do
      it 'creates an experiment_subject record' do
        expect { record_subject_and_variant! }.to change(ExperimentSubject, :count).by(1)
        expect(ExperimentSubject.last.variant).to eq(variant.to_s)
      end
    end

    context 'when an existing experiment_subject exists for the given subject' do
      let_it_be(:experiment_subject) do
        create(:experiment_subject, experiment: experiment, namespace: subject_to_record, user: nil, variant: :experimental)
      end

      context 'when it belongs to the same variant' do
        let(:variant) { :experimental }

        it 'does not initiate a transaction' do
          expect(Experiment.connection).not_to receive(:transaction)

          subject
        end
      end

      context 'but it belonged to a different variant' do
        it 'updates the variant value' do
          expect { record_subject_and_variant! }.to change { experiment_subject.reload.variant }.to('control')
        end
      end
    end

    describe 'providing a subject to record' do
      context 'when given a group as subject' do
        it 'saves the namespace as the experiment subject' do
          expect(record_subject_and_variant!.namespace).to eq(subject_to_record)
        end
      end

      context 'when given a users namespace as subject' do
        let_it_be(:subject_to_record) { build(:namespace) }

        it 'saves the namespace as the experiment_subject' do
          expect(record_subject_and_variant!.namespace).to eq(subject_to_record)
        end
      end

      context 'when given a user as subject' do
        let_it_be(:subject_to_record) { build(:user) }

        it 'saves the user as experiment_subject user' do
          expect(record_subject_and_variant!.user).to eq(subject_to_record)
        end
      end

      context 'when given a project as subject' do
        let_it_be(:subject_to_record) { build(:project) }

        it 'saves the project as experiment_subject user' do
          expect(record_subject_and_variant!.project).to eq(subject_to_record)
        end
      end

      context 'when given no subject' do
        let_it_be(:subject_to_record) { nil }

        it 'raises an error' do
          expect { record_subject_and_variant! }.to raise_error('Incompatible subject provided!')
        end
      end

      context 'when given an incompatible subject' do
        let_it_be(:subject_to_record) { build(:ci_build) }

        it 'raises an error' do
          expect { record_subject_and_variant! }.to raise_error('Incompatible subject provided!')
        end
      end
    end
  end
end
