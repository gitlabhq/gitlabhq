# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experiment do
  include AfterNextHelpers

  subject { build(:experiment) }

  describe 'associations' do
    it { is_expected.to have_many(:experiment_users) }
    it { is_expected.to have_many(:experiment_subjects) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe '.add_user' do
    let_it_be(:experiment_name) { :experiment_key }
    let_it_be(:user) { 'a user' }
    let_it_be(:group) { 'a group' }
    let_it_be(:context) { { a: 42 } }

    subject(:add_user) { described_class.add_user(experiment_name, group, user, context) }

    context 'when an experiment with the provided name does not exist' do
      it 'creates a new experiment record' do
        allow_next_instance_of(described_class) do |experiment|
          allow(experiment).to receive(:record_user_and_group).with(user, group, context)
        end
        expect { add_user }.to change(described_class, :count).by(1)
      end

      it 'forwards the user, group_type, and context to the instance' do
        expect_next_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_user_and_group).with(user, group, context)
        end
        add_user
      end
    end

    context 'when an experiment with the provided name already exists' do
      let_it_be(:experiment) { create(:experiment, name: experiment_name) }

      it 'does not create a new experiment record' do
        allow_next_found_instance_of(described_class) do |experiment|
          allow(experiment).to receive(:record_user_and_group).with(user, group, context)
        end
        expect { add_user }.not_to change(described_class, :count)
      end

      it 'forwards the user, group_type, and context to the instance' do
        expect_next_found_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_user_and_group).with(user, group, context)
        end
        add_user
      end
    end

    it 'works without the optional context argument' do
      allow_next_instance_of(described_class) do |experiment|
        expect(experiment).to receive(:record_user_and_group).with(user, group, {})
      end

      expect { described_class.add_user(experiment_name, group, user) }.not_to raise_error
    end
  end

  describe '.add_group' do
    let_it_be(:experiment_name) { :experiment_key }
    let_it_be(:variant) { :control }
    let_it_be(:group) { build(:group) }

    subject(:add_group) { described_class.add_group(experiment_name, variant: variant, group: group) }

    context 'when an experiment with the provided name does not exist' do
      it 'creates a new experiment record' do
        allow_next(described_class, name: :experiment_key)
          .to receive(:record_subject_and_variant!).with(group, variant)

        expect { add_group }.to change(described_class, :count).by(1)
      end
    end

    context 'when an experiment with the provided name already exists' do
      before do
        create(:experiment, name: experiment_name)
      end

      it 'does not create a new experiment record' do
        expect { add_group }.not_to change(described_class, :count)
      end
    end
  end

  describe '.record_conversion_event' do
    let_it_be(:user) { build(:user) }
    let_it_be(:context) { { a: 42 } }

    let(:experiment_key) { :test_experiment }

    subject(:record_conversion_event) { described_class.record_conversion_event(experiment_key, user, context) }

    context 'when no matching experiment exists' do
      it 'creates the experiment and uses it' do
        expect_next_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_conversion_event_for_user)
        end
        expect { record_conversion_event }.to change { described_class.count }.by(1)
      end

      context 'but we are unable to successfully create one' do
        let(:experiment_key) { nil }

        it 'raises a RecordInvalid error' do
          expect { record_conversion_event }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when a matching experiment already exists' do
      before do
        create(:experiment, name: experiment_key)
      end

      it 'sends record_conversion_event_for_user to the experiment instance' do
        expect_next_found_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_conversion_event_for_user).with(user, context)
        end
        record_conversion_event
      end
    end
  end

  shared_examples 'experiment user with context' do
    let_it_be(:context) { { a: 42, 'b' => 34, 'c': { c1: 100, c2: 'c2', e: :e }, d: [1, 3] } }
    let_it_be(:initial_expected_context) { { 'a' => 42, 'b' => 34, 'c' => { 'c1' => 100, 'c2' => 'c2', 'e' => 'e' }, 'd' => [1, 3] } }

    before do
      subject
      experiment.record_user_and_group(user, :experimental, {})
    end

    it 'has an initial context with stringified keys' do
      expect(ExperimentUser.last.context).to eq(initial_expected_context)
    end

    context 'when updated' do
      before do
        subject
        experiment.record_user_and_group(user, :experimental, new_context)
      end

      context 'with an empty context' do
        let_it_be(:new_context) { {} }

        it 'keeps the initial context' do
          expect(ExperimentUser.last.context).to eq(initial_expected_context)
        end
      end

      context 'with string keys' do
        let_it_be(:new_context) { { f: :some_symbol } }

        it 'adds new symbols stringified' do
          expected_context = initial_expected_context.merge('f' => 'some_symbol')
          expect(ExperimentUser.last.context).to eq(expected_context)
        end
      end

      context 'with atomic values or array values' do
        let_it_be(:new_context) { { b: 97, d: [99] } }

        it 'overrides the values' do
          expected_context = { 'a' => 42, 'b' => 97, 'c' => { 'c1' => 100, 'c2' => 'c2', 'e' => 'e' }, 'd' => [99] }
          expect(ExperimentUser.last.context).to eq(expected_context)
        end
      end

      context 'with nested hashes' do
        let_it_be(:new_context) { { c: { g: 107 } } }

        it 'inserts nested additional values in the same keys' do
          expected_context = initial_expected_context.deep_merge('c' => { 'g' => 107 })
          expect(ExperimentUser.last.context).to eq(expected_context)
        end
      end
    end
  end

  describe '#record_conversion_event_for_user' do
    let_it_be(:user) { create(:user) }
    let_it_be(:experiment) { create(:experiment) }
    let_it_be(:context) { { a: 42 } }

    subject { experiment.record_conversion_event_for_user(user, context) }

    context 'when no existing experiment_user record exists for the given user' do
      it 'does not update or create an experiment_user record' do
        expect { subject }.not_to change { ExperimentUser.all.to_a }
      end
    end

    context 'when an existing experiment_user exists for the given user' do
      context 'but it has already been converted' do
        let!(:experiment_user) { create(:experiment_user, experiment: experiment, user: user, converted_at: 2.days.ago) }

        it 'does not update the converted_at value' do
          expect { subject }.not_to change { experiment_user.converted_at }
        end

        it_behaves_like 'experiment user with context' do
          before do
            experiment.record_user_and_group(user, :experimental, context)
          end
        end
      end

      context 'and it has not yet been converted' do
        let(:experiment_user) { create(:experiment_user, experiment: experiment, user: user) }

        it 'updates the converted_at value' do
          expect { subject }.to change { experiment_user.reload.converted_at }
        end

        it_behaves_like 'experiment user with context' do
          before do
            experiment.record_user_and_group(user, :experimental, context)
          end
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

  describe '#record_user_and_group' do
    let_it_be(:experiment) { create(:experiment) }
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { :control }
    let_it_be(:context) { { a: 42 } }

    subject { experiment.record_user_and_group(user, group, context) }

    context 'when an experiment_user does not yet exist for the given user' do
      it 'creates a new experiment_user record' do
        expect { subject }.to change(ExperimentUser, :count).by(1)
      end

      it 'assigns the correct group_type to the experiment_user' do
        subject

        expect(ExperimentUser.last.group_type).to eq('control')
      end

      it 'adds the correct context to the experiment_user' do
        subject

        expect(ExperimentUser.last.context).to eq({ 'a' => 42 })
      end
    end

    context 'when an experiment_user already exists for the given user' do
      before do
        # Create an existing experiment_user for this experiment and the :control group
        experiment.record_user_and_group(user, :control)
      end

      it 'does not create a new experiment_user record' do
        expect { subject }.not_to change(ExperimentUser, :count)
      end

      context 'when group type or context did not change' do
        let(:context) { {} }

        it 'does not initiate a transaction' do
          expect(Experiment.connection).not_to receive(:transaction)

          subject
        end
      end

      context 'but the group_type and context has changed' do
        let(:group) { :experimental }

        it 'updates the existing experiment_user record with group_type' do
          expect { subject }.to change { ExperimentUser.last.group_type }
        end
      end

      it_behaves_like 'experiment user with context'
    end
  end
end
