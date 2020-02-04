# frozen_string_literal: true

require 'spec_helper'

describe BasePolicy, :do_not_mock_admin_mode do
  include ExternalAuthorizationServiceHelpers
  include AdminModeHelper

  describe '.class_for' do
    it 'detects policy class based on the subject ancestors' do
      expect(DeclarativePolicy.class_for(GenericCommitStatus.new)).to eq(CommitStatusPolicy)
    end

    it 'detects policy class for a presented subject' do
      presentee = Ci::BuildPresenter.new(Ci::Build.new)

      expect(DeclarativePolicy.class_for(presentee)).to eq(Ci::BuildPolicy)
    end

    it 'uses GlobalPolicy when :global is given' do
      expect(DeclarativePolicy.class_for(:global)).to eq(GlobalPolicy)
    end
  end

  describe 'read cross project' do
    let(:current_user) { create(:user) }
    let(:user) { create(:user) }

    subject { described_class.new(current_user, [user]) }

    it { is_expected.to be_allowed(:read_cross_project) }

    context 'when an external authorization service is enabled' do
      before do
        enable_external_authorization_service_check
      end

      it { is_expected.not_to be_allowed(:read_cross_project) }

      context 'for admins' do
        let(:current_user) { build(:admin) }

        subject { described_class.new(current_user, nil) }

        it 'allowed when in admin mode' do
          enable_admin_mode!(current_user)

          is_expected.to be_allowed(:read_cross_project)
        end

        it 'prevented when not in admin mode' do
          is_expected.not_to be_allowed(:read_cross_project)
        end
      end
    end
  end

  describe 'full private access' do
    let(:current_user) { create(:user) }

    subject { described_class.new(current_user, nil) }

    it { is_expected.not_to be_allowed(:read_all_resources) }

    context 'for admins' do
      let(:current_user) { build(:admin) }

      it 'allowed when in admin mode' do
        enable_admin_mode!(current_user)

        is_expected.to be_allowed(:read_all_resources)
      end

      it 'prevented when not in admin mode' do
        is_expected.not_to be_allowed(:read_all_resources)
      end
    end
  end
end
