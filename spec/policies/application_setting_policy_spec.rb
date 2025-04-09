# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ApplicationSettingPolicy do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { create(:user) }

  subject { described_class.new(current_user, [user]) }

  describe 'runner registration token settings' do
    let(:allow_runner_registration_token) { true }

    before do
      stub_application_setting(allow_runner_registration_token: allow_runner_registration_token)
    end

    context 'when anonymous' do
      let(:current_user) { nil }

      it { is_expected.not_to be_allowed(:read_runners_registration_token) }
      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'regular user' do
      it { is_expected.not_to be_allowed(:read_runners_registration_token) }
      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'when external' do
      let_it_be(:current_user) { build(:user, :external) }

      it { is_expected.not_to be_allowed(:read_runners_registration_token) }
      it { is_expected.not_to be_allowed(:update_runners_registration_token) }
    end

    context 'admin' do
      let_it_be(:current_user) { create(:admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it { is_expected.to be_allowed(:read_runners_registration_token) }
        it { is_expected.to be_allowed(:update_runners_registration_token) }

        context 'with registration tokens disabled' do
          let(:allow_runner_registration_token) { false }

          it { is_expected.to be_disallowed(:read_runners_registration_token) }
          it { is_expected.to be_disallowed(:update_runners_registration_token) }
        end
      end

      context 'when admin mode is disabled' do
        it { is_expected.to be_disallowed(:read_runners_registration_token) }
        it { is_expected.to be_disallowed(:update_runners_registration_token) }
      end
    end
  end
end
