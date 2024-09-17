# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerExpirationPolicy, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }

    describe '#cadence' do
      it { is_expected.to validate_presence_of(:cadence) }

      it { is_expected.to allow_value('1d').for(:cadence) }
      it { is_expected.to allow_value('1month').for(:cadence) }
      it { is_expected.not_to allow_value('123asdf').for(:cadence) }
      it { is_expected.not_to allow_value(nil).for(:cadence) }
    end

    describe '#older_than' do
      it { is_expected.to allow_value('7d').for(:older_than) }
      it { is_expected.to allow_value('14d').for(:older_than) }
      it { is_expected.to allow_value(nil).for(:older_than) }
      it { is_expected.not_to allow_value('123asdf').for(:older_than) }
    end

    describe '#keep_n' do
      it { is_expected.to allow_value(10).for(:keep_n) }
      it { is_expected.to allow_value(nil).for(:keep_n) }
      it { is_expected.not_to allow_value('foo').for(:keep_n) }
    end

    describe '#disable!' do
      let_it_be(:policy) { create(:container_expiration_policy) }

      subject { policy.disable! }

      it 'disables the container expiration policy' do
        expect { subject }.to change { policy.reload.enabled }.from(true).to(false)
      end
    end

    describe '#policy_params' do
      let_it_be(:policy) { create(:container_expiration_policy) }

      let(:expected) do
        {
          'older_than' => policy.older_than,
          'keep_n' => policy.keep_n,
          'name_regex' => policy.name_regex,
          'name_regex_keep' => policy.name_regex_keep
        }
      end

      subject { policy.policy_params }

      it { is_expected.to eq(expected) }
    end

    context 'with a set of regexps' do
      let_it_be(:container_expiration_policy) { create(:container_expiration_policy) }

      subject { container_expiration_policy }

      valid_regexps = %w[master .* v.+ v10.1.* (?:v.+|master|release)]
      invalid_regexps = ['[', '(?:v.+|master|release']

      it { is_expected.to validate_presence_of(:name_regex) }

      valid_regexps.each do |valid_regexp|
        it { is_expected.to allow_value(valid_regexp).for(:name_regex) }
        it { is_expected.to allow_value(valid_regexp).for(:name_regex_keep) }
      end

      invalid_regexps.each do |invalid_regexp|
        it { is_expected.not_to allow_value(invalid_regexp).for(:name_regex) }
        it { is_expected.not_to allow_value(invalid_regexp).for(:name_regex_keep) }
      end

      context 'with a disabled container expiration policy' do
        let_it_be(:container_expiration_policy) { create(:container_expiration_policy, :disabled) }

        subject { container_expiration_policy }

        it { is_expected.not_to validate_presence_of(:name_regex) }

        valid_regexps.each do |valid_regexp|
          it { is_expected.to allow_value(valid_regexp).for(:name_regex) }
          it { is_expected.to allow_value(valid_regexp).for(:name_regex_keep) }
        end

        invalid_regexps.each do |invalid_regexp|
          it { is_expected.to allow_value(invalid_regexp).for(:name_regex) }
          it { is_expected.to allow_value(invalid_regexp).for(:name_regex_keep) }
        end
      end
    end
  end

  describe '.preloaded' do
    subject { described_class.preloaded }

    before do
      create_list(:container_expiration_policy, 3)
    end

    it 'preloads the associations' do
      subject

      query = ActiveRecord::QueryRecorder.new { subject.map(&:project).map(&:full_path) }

      expect(query.count).to eq(3)
    end
  end

  describe '.runnable_schedules' do
    subject { described_class.runnable_schedules }

    let!(:policy) { create(:container_expiration_policy, :runnable) }

    it 'returns the runnable schedule' do
      is_expected.to eq([policy])
    end

    context 'when there are no runnable schedules' do
      let!(:policy) {}

      it 'returns an empty array' do
        is_expected.to be_empty
      end
    end
  end

  context 'policies with container repositories' do
    let_it_be(:policy1) { create(:container_expiration_policy) }
    let_it_be(:container_repository1) { create(:container_repository, project: policy1.project) }
    let_it_be(:policy2) { create(:container_expiration_policy) }
    let_it_be(:container_repository2) { create(:container_repository, project: policy2.project) }
    let_it_be(:policy3) { create(:container_expiration_policy) }

    describe '.with_container_repositories' do
      subject { described_class.with_container_repositories }

      it { is_expected.to contain_exactly(policy1, policy2) }
    end

    describe '.without_container_repositories' do
      subject { described_class.without_container_repositories }

      it { is_expected.to contain_exactly(policy3) }
    end
  end
end
