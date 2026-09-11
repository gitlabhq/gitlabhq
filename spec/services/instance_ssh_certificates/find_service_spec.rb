# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSshCertificates::FindService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:certificate) { create(:instance_ssh_certificate) }

  let(:ca_fingerprint) { certificate.fingerprint }
  let(:user_identifier) { user.username }

  subject(:result) { described_class.new(ca_fingerprint, user_identifier).execute }

  shared_examples 'resolving the user' do
    it 'returns the user matching the identifier', :aggregate_failures do
      expect(result).to be_success
      expect(result.payload).to eq({ user: user })
    end
  end

  it_behaves_like 'resolving the user'

  context 'when the user is identified by primary email' do
    let(:user_identifier) { user.email }

    it_behaves_like 'resolving the user'
  end

  context 'when no certificate matches the fingerprint' do
    let_it_be(:unregistered) { build(:instance_ssh_certificate) }

    let(:ca_fingerprint) { unregistered.fingerprint }

    it_behaves_like 'returning an error service response', message: 'Certificate Not Found',
      reason: :certificate_not_found
  end

  context 'when the fingerprint is not a valid base64 SHA256 digest' do
    let(:ca_fingerprint) { 'invalid' }

    it_behaves_like 'returning an error service response', message: 'Certificate Not Found',
      reason: :certificate_not_found
  end

  context 'when no user matches the identifier' do
    let(:user_identifier) { 'nonexistent' }

    it_behaves_like 'returning an error service response', message: 'User Not Found', reason: :user_not_found
  end

  # Account state is enforced downstream by /internal/allowed, through the :access_git rule
  # in GlobalPolicy. The group scope resolves these users too, so resolution here stays in
  # step with it rather than authenticating on a second, narrower rule.
  %i[banned blocked deactivated].each do |state|
    context "when the user is #{state}" do
      let_it_be(:user) { create(:user, state) }

      it_behaves_like 'resolving the user'
    end
  end

  context 'when the feature flag is disabled' do
    before do
      stub_feature_flags(instance_ssh_certificates: false)
    end

    it_behaves_like 'returning an error service response', message: 'Certificate Not Found',
      reason: :certificate_not_found

    it 'does not query for the certificate' do
      expect(InstanceSshCertificate).not_to receive(:for_fingerprint)

      result
    end
  end

  context 'on GitLab.com', :saas do
    it_behaves_like 'returning an error service response', message: 'Certificate Not Found',
      reason: :certificate_not_found
  end
end
