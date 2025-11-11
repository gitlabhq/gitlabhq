# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SignedTag, feature_category: :source_code_management do
  let_it_be(:project) { create :project, :repository }

  describe '#lazy_cached_signature' do
    def build_tag_context(id:)
      {
        has_signature: true,
        id: Digest::SHA256.hexdigest(id),
        user_email: generate(:email)
      }
    end

    let(:gpg_git_tag) { build_tag_context(id: 'git_tag_id1') }
    let(:ssh_git_tag) { build_tag_context(id: 'git_tag_id3') }
    let(:git_tags) do
      [
        Gitlab::Gpg::Tag.new(project.repository, gpg_git_tag),
        Gitlab::Ssh::Tag.new(project.repository, ssh_git_tag)
      ]
    end

    subject(:batch_verification_status) { git_tags.map(&:lazy_cached_signature).map(&:verification_status) }

    context 'when the type of signature is not cached in a table' do
      let(:x509_git_tag) { build_tag_context(id: 'git_tag_id1') }

      subject(:x509_cached_signature) do
        Gitlab::X509::Tag.new(project.repository, x509_git_tag).lazy_cached_signature
      end

      it 'returns nil' do
        expect(Gitlab::Git::Tag).not_to receive(:batch_signature_extraction)

        expect(x509_cached_signature).to be_nil
      end
    end

    it 'batches rpc calls and creates a new tag signature' do
      expect(Gitlab::Git::Tag).to receive(:batch_signature_extraction).with(
        project.repository,
        git_tags.map(&:object_name),
        timeout: Gitlab::GitalyClient.fast_timeout
      ).and_return({
        gpg_git_tag[:id] => [
          GpgHelpers::User1.signed_commit_signature,
          GpgHelpers::User1.signed_commit_base_data
        ],
        ssh_git_tag[:id] => ['', '']
      })

      expect do
        batch_verification_status
      end.to change { Repositories::Tags::GpgSignature.count }.from(0).to(1)
      .and change { Repositories::Tags::SshSignature.count }.from(0).to(1)

      expect(batch_verification_status).to eq(%w[unknown_key unverified])
    end

    context 'when called for multiple tags of the same type' do
      let(:gpg_git_tag2) { build_tag_context(id: 'git_tag_id2') }
      let(:ssh_git_tag2) { build_tag_context(id: 'git_tag_id4') }

      let(:git_tags) do
        [
          Gitlab::Gpg::Tag.new(project.repository, gpg_git_tag),
          Gitlab::Ssh::Tag.new(project.repository, ssh_git_tag),
          Gitlab::Gpg::Tag.new(project.repository, gpg_git_tag2),
          Gitlab::Ssh::Tag.new(project.repository, ssh_git_tag2)
        ]
      end

      it 'batches insert' do
        expect(Gitlab::Git::Tag).to receive(:batch_signature_extraction).with(
          project.repository,
          git_tags.map(&:object_name),
          timeout: Gitlab::GitalyClient.fast_timeout
        ).and_return({
          gpg_git_tag[:id] => [
            GpgHelpers::User1.signed_commit_signature,
            GpgHelpers::User1.signed_commit_base_data
          ],
          gpg_git_tag2[:id] => [
            GpgHelpers::User3.signed_commit_signature,
            GpgHelpers::User3.signed_commit_base_data
          ],
          ssh_git_tag[:id] => ['', ''],
          ssh_git_tag2[:id] => ['', '']
        })

        expect(Repositories::Tags::GpgSignature).to receive(:bulk_insert!).with(an_array_matching([
          an_object_having_attributes(object_name: gpg_git_tag[:id]),
          an_object_having_attributes(object_name: gpg_git_tag2[:id])
        ])).and_call_original

        expect(Repositories::Tags::SshSignature).to receive(:bulk_insert!).with(an_array_matching([
          an_object_having_attributes(object_name: ssh_git_tag[:id]),
          an_object_having_attributes(object_name: ssh_git_tag2[:id])
        ])).and_call_original

        expect do
          batch_verification_status
        end.to change { Repositories::Tags::GpgSignature.count }.from(0).to(2)
        .and change { Repositories::Tags::SshSignature.count }.from(0).to(2)
      end

      context 'when some tags are cached' do
        let!(:tag_gpg_signature) do
          create :tag_gpg_signature, project: project, object_name: gpg_git_tag[:id], gpg_key: create(:gpg_key)
        end

        let!(:tag_ssh_signature) do
          create :tag_ssh_signature, project: project, object_name: ssh_git_tag[:id]
        end

        it 'updates the cache with the missing tags' do
          expect(Gitlab::Git::Tag).to receive(:batch_signature_extraction).with(
            project.repository,
            [gpg_git_tag2[:id], ssh_git_tag2[:id]],
            timeout: Gitlab::GitalyClient.fast_timeout
          ).and_return({
            gpg_git_tag2[:id] => [
              GpgHelpers::User3.signed_commit_signature,
              GpgHelpers::User3.signed_commit_base_data
            ],
            ssh_git_tag2[:id] => ['', '']
          })
          expect(Repositories::Tags::GpgSignature).to receive(:bulk_insert!).with(an_array_matching([
            an_object_having_attributes(object_name: gpg_git_tag2[:id])
          ])).and_call_original

          expect(Repositories::Tags::SshSignature).to receive(:bulk_insert!).with(an_array_matching([
            an_object_having_attributes(object_name: ssh_git_tag2[:id])
          ])).and_call_original

          expect do
            batch_verification_status
          end.to change { Repositories::Tags::GpgSignature.count }.from(1).to(2)
          .and change { Repositories::Tags::SshSignature.count }.from(1).to(2)

          expect(git_tags[0].lazy_cached_signature).to eq(tag_gpg_signature)
          expect(git_tags[1].lazy_cached_signature).to eq(tag_ssh_signature)
        end
      end
    end
  end
end
