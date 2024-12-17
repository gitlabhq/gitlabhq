# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Onboarding::StatusPresenter, feature_category: :onboarding do
  let(:member) { build_stubbed(:group_member) }
  let(:members) { [member] }
  let(:user) { build_stubbed(:user, members: members) }

  describe '.registration_path_params' do
    let(:params) { { some: 'thing' } }

    subject { described_class.registration_path_params(params: params) }

    it { is_expected.to eq({}) }
  end

  describe '#registration_omniauth_params' do
    let(:params) { { glm_source: 'source', glm_content: 'content', extra: 'param' } }

    subject { described_class.new(params, nil, nil).registration_omniauth_params }

    it { is_expected.to eq({}) }
  end

  describe '#single_invite?' do
    subject { described_class.new(nil, nil, user).single_invite? }

    context 'when there is only one member for the user' do
      context 'when the member source exists' do
        it { is_expected.to be(true) }
      end
    end

    context 'when there is more than one member for the user' do
      let(:members) { [member, build_stubbed(:group_member)] }

      it { is_expected.to be(false) }
    end

    context 'when there are no members for the user' do
      let(:user) { build_stubbed(:user) }

      it { is_expected.to be(false) }
    end
  end

  describe '#last_invited_member' do
    subject { described_class.new(nil, nil, user).last_invited_member }

    it { is_expected.to eq(member) }

    context 'when another member exists and is most recent' do
      let(:last_member) { build_stubbed(:group_member) }
      let(:members) { [member, last_member] }

      it { is_expected.to eq(last_member) }
    end

    context 'when there are no members' do
      let(:members) { [] }

      it { is_expected.to be_nil }
    end
  end

  describe '#last_invited_member_source' do
    subject { described_class.new(nil, nil, user).last_invited_member_source }

    context 'when a member exists' do
      it { is_expected.to eq(member.group) }
    end

    context 'when no members exist' do
      let(:members) { [] }

      it { is_expected.to be_nil }
    end

    context 'when another member exists and is most recent' do
      let(:last_member) { build_stubbed(:group_member) }
      let(:members) { [member, last_member] }

      it { is_expected.to eq(last_member.group) }
    end
  end
end
