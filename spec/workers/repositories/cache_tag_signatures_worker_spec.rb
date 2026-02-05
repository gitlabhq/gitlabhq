# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::CacheTagSignaturesWorker, feature_category: :source_code_management do
  describe '#perform' do
    let_it_be(:project) { create(:project, :repository) }
    let(:gpg_tag_context) do
      {
        has_signature: true,
        id: 'gpg_tag',
        user_email: generate(:email)
      }
    end

    let(:ssh_tag_context) do
      {
        has_signature: true,
        id: 'ssh_tag',
        user_email: generate(:email)
      }
    end

    let(:gpg_tag) { Gitlab::Gpg::Tag.new(project.repository, gpg_tag_context) }
    let(:ssh_tag) { Gitlab::Ssh::Tag.new(project.repository, ssh_tag_context) }

    let(:params) do
      {
        'class_to_context' => {
          "Gitlab::Gpg::Tag" => [gpg_tag_context],
          "Gitlab::Ssh::Tag" => [ssh_tag_context]
        }
      }
    end

    let(:project_id) { project.id }

    subject(:perform) { described_class.new.perform(project_id, params) }

    before do
      allow(Gitlab::Git::Tag).to receive(:batch_signature_extraction).with(
        project.repository,
        [gpg_tag_context[:id], ssh_tag_context[:id]], timeout: Gitlab::GitalyClient.medium_timeout
      ).and_return(
        {
          gpg_tag_context[:id] => [
            GpgHelpers::User1.signed_commit_signature,
            GpgHelpers::User1.signed_commit_base_data
          ],
          ssh_tag_context[:id] => ['', '']
        }
      )
    end

    context 'when the project does not exist' do
      let(:project_id) { nil }

      it 'returns without caching' do
        expect { perform }.not_to raise_error

        expect(Repositories::Tags::GpgSignature.count).to eq(0)
        expect(Repositories::Tags::SshSignature.count).to eq(0)
      end
    end

    it 'caches tag signatures' do
      expect do
        perform
      end.to change { Repositories::Tags::GpgSignature.count }.from(0).to(1)
        .and change { Repositories::Tags::SshSignature.count }.from(0).to(1)
    end

    context 'when class_to_context parameters include unsupported classes' do
      let(:params) do
        {
          'class_to_context' => {
            "Gitlab::X509::Tag" => [{}],
            "Gitlab::Gpg::Tag" => [gpg_tag_context],
            "Gitlab::Ssh::Tag" => [ssh_tag_context]
          }
        }
      end

      it 'ignores the unsupported class and caches tag signatures' do
        expect do
          perform
        end.to change { Repositories::Tags::GpgSignature.count }.from(0).to(1)
          .and change { Repositories::Tags::SshSignature.count }.from(0).to(1)
      end
    end

    context 'when the rpc times out' do
      before do
        allow(Gitlab::Git::Tag).to receive(:batch_signature_extraction).and_raise(GRPC::DeadlineExceeded)
      end

      it 'does not cache any tag signatures' do
        perform

        expect(Repositories::Tags::GpgSignature.count).to eq(0)
        expect(Repositories::Tags::SshSignature.count).to eq(0)
      end

      it 'does not raise any errors' do
        expect { perform }.not_to raise_error
      end

      it 'does not enqueue another worker' do
        perform

        expect(described_class.jobs.size).to eq(0)
      end
    end
  end
end
