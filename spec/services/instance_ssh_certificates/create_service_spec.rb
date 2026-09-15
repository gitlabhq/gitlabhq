# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InstanceSshCertificates::CreateService, :enable_admin_mode, feature_category: :source_code_management do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:admin) { create(:admin) }
  let(:current_user) { admin }
  let(:key) { build(:rsa_key_4096).key }
  let(:title) { 'Instance CA' }
  let(:params) { { title: title, key: key } }

  subject(:result) { described_class.new(current_user: current_user, params: params).execute }

  describe '#execute' do
    it 'creates a certificate with its SHA256 fingerprint', :aggregate_failures do
      expect { result }.to change { InstanceSshCertificate.count }.by(1)

      expect(result).to be_success
      expect(result.payload).to have_attributes(
        title: title,
        key: key,
        fingerprint: Gitlab::SSHPublicKey.new(key).fingerprint_sha256.delete_prefix('SHA256:')
      )
      expect(result.payload).to be_persisted
    end

    context 'with an invalid key' do
      where(:key) { [nil, '', 'not a key', 'ssh-rsa AAAB3NzaC1yc2EAAAADAQABAAAAgQCxT+'] }

      with_them do
        it 'returns a key-oriented error without creating a certificate', :aggregate_failures do
          expect { result }.not_to change { InstanceSshCertificate.count }

          expect(result).to be_error
          expect(result.reason).to eq(:unprocessable_entity)
          expect(result.message).to eq('Validation failed: Invalid key')
        end
      end
    end

    context 'with an invalid title' do
      where(:title) { [nil, '', 'a' * 256] }

      with_them do
        it 'returns a validation error', :aggregate_failures do
          expect { result }.not_to change { InstanceSshCertificate.count }

          expect(result).to be_error
          expect(result.reason).to eq(:unprocessable_entity)
          expect(result.message).to include('Validation failed: Title')
        end
      end
    end

    context 'with invalid UTF-8 in the key' do
      let(:key) { "#{super()}\xFF" }

      it 'rescues the argument error without creating a certificate', :aggregate_failures do
        expect { result }.not_to change { InstanceSshCertificate.count }

        expect(result).to be_error
        expect(result.reason).to eq(:unprocessable_entity)
        expect(result.message).to eq('invalid byte sequence in UTF-8')
      end
    end

    context 'when the CA already exists' do
      before do
        create(:instance_ssh_certificate, key: key)
      end

      it 'rejects the duplicate', :aggregate_failures do
        expect { result }.not_to change { InstanceSshCertificate.count }

        expect(result).to be_error
        expect(result.reason).to eq(:unprocessable_entity)
        expect(result.message).to include('This CA has already been configured.')
      end
    end

    context 'when a concurrent insert violates the unique index' do
      before do
        allow(InstanceSshCertificate).to receive(:create!).and_raise(ActiveRecord::RecordNotUnique)
      end

      it_behaves_like 'returning an error service response',
        message: 'Validation failed: Fingerprint must be unique. This CA has already been configured.',
        reason: :unprocessable_entity
    end

    context 'when the caller is not an admin' do
      let(:current_user) { build_stubbed(:user) }

      it 'rejects the caller without creating a certificate', :aggregate_failures do
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

      it 'does not create a certificate', :aggregate_failures do
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
