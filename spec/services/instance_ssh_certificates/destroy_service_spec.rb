# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSshCertificates::DestroyService, :enable_admin_mode, feature_category: :source_code_management do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:certificate) { create(:instance_ssh_certificate, key: build(:rsa_key_4096).key) }
  let(:certificate_id) { certificate.id }
  let(:current_user) { admin }

  subject(:result) { described_class.new(certificate_id, current_user: current_user).execute }

  describe '#execute' do
    it 'destroys the certificate', :aggregate_failures do
      expect { result }.to change { InstanceSshCertificate.count }.by(-1)

      expect(result).to be_success
      expect(result.payload[:ssh_certificate]).to eq(certificate)
      expect(result.payload[:ssh_certificate]).to be_destroyed
    end

    context 'when the certificate does not exist' do
      let(:certificate_id) { non_existing_record_id }

      it_behaves_like 'returning an error service response',
        message: 'SSH Certificate not found', reason: :not_found
    end

    context 'when the certificate ID is absent' do
      let(:certificate_id) { nil }

      it_behaves_like 'returning an error service response', reason: :not_found
    end

    context 'when the certificate cannot be destroyed' do
      before do
        allow_next_found_instance_of(InstanceSshCertificate) do |record|
          allow(record).to receive(:destroy!).and_raise(ActiveRecord::RecordNotDestroyed)
        end
      end

      it 'returns an error', :aggregate_failures do
        expect(result).to be_error
        expect(result.reason).to eq(:unprocessable_entity)
        expect(result.message).to eq('SSH Certificate could not be deleted')
      end
    end

    context 'when the caller is not an admin' do
      let(:current_user) { build_stubbed(:user) }

      it 'rejects the caller without deleting the certificate', :aggregate_failures do
        expect { result }.not_to change { InstanceSshCertificate.count }

        expect(result).to be_error
        expect(result.reason).to eq(:forbidden)
      end
    end

    context 'when the caller is absent' do
      let(:current_user) { nil }

      it_behaves_like 'returning an error service response', reason: :forbidden
    end

    context 'when the feature flag is disabled' do
      before do
        stub_feature_flags(instance_ssh_certificates: false)
      end

      it 'does not delete the certificate', :aggregate_failures do
        expect { result }.not_to change { InstanceSshCertificate.count }

        expect(result).to be_error
        expect(result.reason).to eq(:not_found)
      end
    end

    context 'on GitLab.com', :saas do
      it_behaves_like 'returning an error service response', reason: :not_found
    end
  end
end
