# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Experiment do
  subject { build(:experiment) }

  describe 'associations' do
    it { is_expected.to have_many(:experiment_users) }
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:control_group_users) }
    it { is_expected.to have_many(:experimental_group_users) }

    describe 'control_group_users and experimental_group_users' do
      let(:experiment) { create(:experiment) }
      let(:control_group_user) { build(:user) }
      let(:experimental_group_user) { build(:user) }

      before do
        experiment.control_group_users << control_group_user
        experiment.experimental_group_users << experimental_group_user
      end

      describe 'control_group_users' do
        subject { experiment.control_group_users }

        it { is_expected.to contain_exactly(control_group_user) }
      end

      describe 'experimental_group_users' do
        subject { experiment.experimental_group_users }

        it { is_expected.to contain_exactly(experimental_group_user) }
      end
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe '.add_user' do
    let(:name) { :experiment_key }
    let(:user) { build(:user) }

    let!(:experiment) { create(:experiment, name: name) }

    subject { described_class.add_user(name, :control, user) }

    describe 'creating a new experiment record' do
      context 'an experiment with the provided name already exists' do
        it 'does not create a new experiment record' do
          expect { subject }.not_to change(Experiment, :count)
        end
      end

      context 'an experiment with the provided name does not exist yet' do
        let(:experiment) { nil }

        it 'creates a new experiment record' do
          expect { subject }.to change(Experiment, :count).by(1)
        end
      end
    end

    describe 'creating a new experiment_user record' do
      context 'an experiment_user record for this experiment already exists' do
        before do
          subject
        end

        it 'does not create a new experiment_user record' do
          expect { subject }.not_to change(ExperimentUser, :count)
        end
      end

      context 'an experiment_user record for this experiment does not exist yet' do
        it 'creates a new experiment_user record' do
          expect { subject }.to change(ExperimentUser, :count).by(1)
        end

        it 'assigns the correct group_type to the experiment_user' do
          expect { subject }.to change { experiment.control_group_users.count }.by(1)
        end
      end
    end
  end

  describe '#add_control_user' do
    let(:experiment) { create(:experiment) }
    let(:user) { build(:user) }

    subject { experiment.add_control_user(user) }

    it 'creates a new experiment_user record and assigns the correct group_type' do
      expect { subject }.to change { experiment.control_group_users.count }.by(1)
    end
  end

  describe '#add_experimental_user' do
    let(:experiment) { create(:experiment) }
    let(:user) { build(:user) }

    subject { experiment.add_experimental_user(user) }

    it 'creates a new experiment_user record and assigns the correct group_type' do
      expect { subject }.to change { experiment.experimental_group_users.count }.by(1)
    end
  end
end
