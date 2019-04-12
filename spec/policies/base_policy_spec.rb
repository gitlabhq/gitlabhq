require 'spec_helper'

describe BasePolicy do
  include ExternalAuthorizationServiceHelpers

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

      it 'allows admins' do
        expect(described_class.new(build(:admin), nil)).to be_allowed(:read_cross_project)
      end
    end
  end
end
