# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Users::UpdateTwoFactorRequirementService, feature_category: :system_access do
  let_it_be_with_refind(:user) { create(:user) }

  let(:service) { described_class.new(user) }

  describe '#execute' do
    subject(:execute) { service.execute }

    it 'returns a success response with the user', :aggregate_failures do
      expect(execute).to be_success
      expect(execute.payload[:user]).to eq(user)
    end

    context 'with 2FA requirement on groups' do
      let_it_be(:group1) do
        create :group, owners: user, require_two_factor_authentication: true, two_factor_grace_period: 23
      end

      let_it_be(:group2) do
        create :group, owners: user, require_two_factor_authentication: true, two_factor_grace_period: 32
      end

      before do
        execute
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end

      it 'uses the shortest grace period' do
        expect(user.two_factor_grace_period).to be 23
      end
    end

    context 'with 2FA requirement from expanded groups' do
      let!(:group1) { create :group, require_two_factor_authentication: true }
      let!(:group1a) { create :group, parent: group1, owners: user }

      before do
        execute
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'with 2FA requirement on nested child group' do
      let!(:group1) { create :group, require_two_factor_authentication: false, owners: user }
      let!(:group1a) { create :group, require_two_factor_authentication: true, parent: group1 }

      before do
        execute
      end

      it 'requires 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be true
      end
    end

    context 'with a multi-branch group tree' do
      #                group
      #        _______ (foo) _______
      #       |                     |
      #       |                     |
      # nested_group_1        nested_group_2
      # (bar)                 (barbaz)
      #       |                     |
      #       |                     |
      # nested_group_1_1      nested_group_2_1
      # (baz)                 (baz)
      #
      let_it_be_with_reload(:group) { create :group }
      let_it_be_with_reload(:nested_group_1) { create :group, parent: group, name: 'bar', owners: user }
      let_it_be_with_reload(:nested_group_1_1) { create :group, parent: nested_group_1, name: 'baz' }
      let_it_be_with_reload(:nested_group_2) { create :group, parent: group, name: 'barbaz' }
      let_it_be_with_reload(:nested_group_2_1) { create :group, parent: nested_group_2, name: 'baz' }

      it 'requires 2FA when an ancestor group requires it' do
        group.update!(require_two_factor_authentication: true)

        execute

        expect(user.require_two_factor_authentication_from_group).to be true
      end

      it 'requires 2FA when a descendant group requires it' do
        nested_group_1_1.update!(require_two_factor_authentication: true)

        execute

        expect(user.require_two_factor_authentication_from_group).to be true
      end

      it 'does not require 2FA when only a sibling branch requires it' do
        nested_group_2_1.update!(require_two_factor_authentication: true)

        execute

        expect(user.require_two_factor_authentication_from_group).to be false
      end
    end

    context "with 2FA requirement from shared project's group" do
      let_it_be(:group1) { create :group, require_two_factor_authentication: true }
      let_it_be(:group2) { create :group, owners: user }
      let_it_be(:shared_project) { create(:project, namespace: group1) }

      before_all do
        shared_project.project_group_links.create!(
          group: group2
        )
      end

      it 'does not require 2FA' do
        execute

        expect(user.require_two_factor_authentication_from_group).to be false
      end
    end

    context 'without 2FA requirement on groups' do
      let!(:group) { create :group, owners: user }

      before do
        execute
      end

      it 'does not require 2FA' do
        expect(user.require_two_factor_authentication_from_group).to be false
      end

      it 'falls back to the default grace period' do
        expect(user.two_factor_grace_period).to be 48
      end
    end

    context 'when the user fails to save' do
      before do
        user.update_columns(email: '')
      end

      it 'returns an error response with the user', :aggregate_failures do
        expect(execute).to be_error
        expect(execute.message).to include("Email can't be blank")
        expect(execute.payload[:user]).to eq(user)
      end

      it 'logs the failure' do
        expect(::Gitlab::AppLogger).to receive(:warn).with(hash_including(
          ::Labkit::Fields::CLASS_NAME => described_class.name,
          ::Labkit::Fields::ERROR_MESSAGE => "Email can't be blank",
          ::Labkit::Fields::GL_USER_ID => user.id
        ))

        execute
      end
    end

    context 'when the user is not saved' do
      let(:user) { build(:user) }

      it 'returns a success response' do
        expect(execute).to be_success
      end
    end

    context 'when the record is frozen' do
      before do
        user.freeze
      end

      it 'returns an error response' do
        expect(execute).to be_error
      end
    end
  end
end
