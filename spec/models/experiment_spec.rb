# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experiment do
  subject { build(:experiment) }

  describe 'associations' do
    it { is_expected.to have_many(:experiment_users) }
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

    subject(:add_user) { described_class.add_user(experiment_name, group, user) }

    context 'when an experiment with the provided name does not exist' do
      it 'creates a new experiment record' do
        allow_next_instance_of(described_class) do |experiment|
          allow(experiment).to receive(:record_user_and_group).with(user, group)
        end
        expect { add_user }.to change(described_class, :count).by(1)
      end

      it 'forwards the user and group_type to the instance' do
        expect_next_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_user_and_group).with(user, group)
        end
        add_user
      end
    end

    context 'when an experiment with the provided name already exists' do
      let_it_be(:experiment) { create(:experiment, name: experiment_name) }

      it 'does not create a new experiment record' do
        allow_next_found_instance_of(described_class) do |experiment|
          allow(experiment).to receive(:record_user_and_group).with(user, group)
        end
        expect { add_user }.not_to change(described_class, :count)
      end

      it 'forwards the user and group_type to the instance' do
        expect_next_found_instance_of(described_class) do |experiment|
          expect(experiment).to receive(:record_user_and_group).with(user, group)
        end
        add_user
      end
    end
  end

  describe '#record_user_and_group' do
    let_it_be(:experiment) { create(:experiment) }
    let_it_be(:user) { create(:user) }

    let(:group) { :control }

    subject(:record_user_and_group) { experiment.record_user_and_group(user, group) }

    context 'when an experiment_user does not yet exist for the given user' do
      it 'creates a new experiment_user record' do
        expect { record_user_and_group }.to change(ExperimentUser, :count).by(1)
      end

      it 'assigns the correct group_type to the experiment_user' do
        record_user_and_group
        expect(ExperimentUser.last.group_type).to eq('control')
      end
    end

    context 'when an experiment_user already exists for the given user' do
      before do
        # Create an existing experiment_user for this experiment and the :control group
        experiment.record_user_and_group(user, :control)
      end

      it 'does not create a new experiment_user record' do
        expect { record_user_and_group }.not_to change(ExperimentUser, :count)
      end

      context 'but the group_type has changed' do
        let(:group) { :experimental }

        it 'updates the existing experiment_user record' do
          expect { record_user_and_group }.to change { ExperimentUser.last.group_type }
        end
      end
    end
  end
end
