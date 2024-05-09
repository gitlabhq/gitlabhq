# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::Integrations::BeyondIdentityCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'
  let(:integration_check) { Gitlab::Checks::IntegrationsCheck.new(changes_access) }
  let!(:beyond_identity_integration) { create(:beyond_identity_integration) }

  subject(:check) { described_class.new(integration_check) }

  describe '#validate!' do
    shared_examples_for 'exclusion from the check' do
      context 'when the project is excluded from the check' do
        let!(:integration_exclusion) do
          create(:beyond_identity_integration, active: false, project: project, inherit_from_id: nil, instance: false)
        end

        it 'does not raise an error' do
          expect { check.validate! }.not_to raise_error
        end

        context 'and the integration is not activated' do
          let(:beyond_identity_integration) { nil }

          it 'does not raise an error' do
            expect { check.validate! }.not_to raise_error
          end
        end
      end
    end

    context 'when commit without GPG signature' do
      let_it_be_with_reload(:project) { create(:project, :repository) }

      let_it_be(:oldrev) { '1e292f8fedd741b75372e19097c76d327140c312' }
      let_it_be(:newrev) { '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9' }

      before_all do
        project.repository.delete_branch('ssh-signed-commit')
      end

      it 'is rejected' do
        expect { check.validate! }
          .to raise_error(::Gitlab::GitAccess::ForbiddenError, 'Commit is not signed with a GPG signature')
      end

      it_behaves_like 'exclusion from the check'

      context 'when the push happens from web' do
        let(:protocol) { 'web' }

        it 'does not raise an error' do
          expect { check.validate! }.not_to raise_error
        end
      end

      context 'when the push performed by service account' do
        let_it_be(:user) { create(:user, :service_account) }

        it 'is rejected' do
          expect { check.validate! }
            .to raise_error(::Gitlab::GitAccess::ForbiddenError, 'Commit is not signed with a GPG signature')
        end

        context 'when service accounts are excluded' do
          let!(:beyond_identity_integration) do
            create(:beyond_identity_integration, exclude_service_accounts: true)
          end

          it 'does not raise an error' do
            expect { check.validate! }.not_to raise_error
          end
        end
      end
    end

    context 'when a commit with GPG signature' do
      let_it_be_with_reload(:project) { create(:project, :repository) }
      let_it_be(:oldrev) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }
      let_it_be(:newrev) { 'f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373' }
      let!(:gpg_key) { create :gpg_key, externally_verified: true }

      before do
        gpg_key.update_column(:fingerprint, 'A328467F793DBC6033FEA1B9EDD30D2BEB691AC9')
        project.repository.delete_branch('trailers')
      end

      it_behaves_like 'exclusion from the check'

      context 'and the signature is unverified' do
        it 'is rejected' do
          expect { check.validate! }
            .to raise_error(::Gitlab::GitAccess::ForbiddenError,
              'Signature of the commit f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373 is not verified')
        end
      end

      context 'when key verification by integrations is stale' do
        let!(:gpg_key) do
          create :gpg_key, externally_verified: externally_verified,
            updated_at: (described_class::INTEGRATION_VERIFICATION_PERIOD + 1.day).ago
        end

        before do
          allow(Integrations::BeyondIdentity).to receive(:for_instance).and_return([beyond_identity_integration])
        end

        context 'and the signature is verified' do
          before do
            allow_next_instances_of(CommitSignatures::GpgSignature, 3) do |signature|
              allow(signature).to receive(:verified?).and_return(true)
              allow(signature).to receive(:gpg_key).and_return(gpg_key)
            end
          end

          let(:externally_verified) { true }

          context 'and the key is not verified' do
            let(:externally_verified) { false }

            it 'raises an error without calling integrations' do
              expect(GpgKeys::ValidateIntegrationsService).not_to receive(:new)
              expect { check.validate! }
              .to raise_error(::Gitlab::GitAccess::ForbiddenError,
                'GPG Key used to sign commit f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373 is not verified')
            end
          end

          context 'when not verified by integrations' do
            before do
              allow(beyond_identity_integration).to receive(:execute).and_raise(
                ::Gitlab::BeyondIdentity::Client::ApiError.new('error', 403)
              )
            end

            it 'raises an error' do
              expect { check.validate! }
              .to raise_error(::Gitlab::GitAccess::ForbiddenError,
                'GPG Key used to sign commit f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373 is not verified')
              expect(gpg_key.reload.externally_verified).to eq(false)
            end
          end

          context 'when verified by integrations' do
            before do
              allow(beyond_identity_integration).to receive(:execute)
            end

            it 'does not raise an error' do
              expect { check.validate! }.not_to raise_error
            end

            it 'updates updated_at' do
              freeze_time do
                expect { check.validate! }.to change { gpg_key.reload.updated_at }.to(Time.current)
              end
            end
          end
        end
      end
    end
  end
end
