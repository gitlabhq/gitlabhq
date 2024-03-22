# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::Integrations::BeyondIdentityCheck, feature_category: :source_code_management do
  include_context 'changes access checks context'

  let!(:beyond_identity_integration) { create(:beyond_identity_integration) }

  let(:integration_check) { Gitlab::Checks::IntegrationsCheck.new(changes_access) }

  subject(:check) { described_class.new(integration_check) }

  describe '#validate!' do
    context 'when commit without GPG signature' do
      let_it_be(:project) { create(:project, :repository) }

      let_it_be(:oldrev) { '1e292f8fedd741b75372e19097c76d327140c312' }
      let_it_be(:newrev) { '7b5160f9bb23a3d58a0accdbe89da13b96b1ece9' }

      before_all do
        project.repository.delete_branch('ssh-signed-commit')
      end

      it 'is rejected' do
        expect { check.validate! }
          .to raise_error(::Gitlab::GitAccess::ForbiddenError, 'Commit is not signed by a GPG signature')
      end

      context 'when the push happens from web' do
        let(:protocol) { 'web' }

        it 'does not raise an error' do
          expect { check.validate! }.not_to raise_error
        end
      end
    end

    context 'when a commit with GPG signature' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:oldrev) { 'ddd0f15ae83993f5cb66a927a28673882e99100b' }
      let_it_be(:newrev) { 'f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373' }

      before do
        project.repository.delete_branch('trailers')
      end

      context 'and the signature is unverified' do
        it 'is rejected' do
          expect { check.validate! }
            .to raise_error(::Gitlab::GitAccess::ForbiddenError,
              'Signature of the commit f0a5ed60d24c98ec6d00ac010c1f3f01ee0a8373 is not verified')
        end
      end

      context 'and the signature is verified' do
        it 'does not raise an error' do
          allow_next_instances_of(CommitSignatures::GpgSignature, 3) do |signature|
            allow(signature).to receive(:verified?).and_return(true)
          end

          expect { check.validate! }.not_to raise_error
        end
      end
    end
  end
end
