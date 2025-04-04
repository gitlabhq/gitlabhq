# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ContainerRegistry::Tag, feature_category: :container_registry do
  let_it_be(:group) { create(:group, name: 'group') }
  let_it_be_with_refind(:project) { create(:project, path: 'test', group: group) }
  let_it_be_with_refind(:repository) { create(:container_repository, name: '', project: project) }

  let(:headers) do
    { 'Accept' => ContainerRegistry::Client::ACCEPTED_TYPES.join(', ') }
  end

  let(:tag) { described_class.new(repository, 'tag') }

  before do
    stub_container_registry_config(enabled: true, api_url: 'http://registry.gitlab', host_port: 'registry.gitlab')
  end

  it { expect(tag).to respond_to(:repository) }
  it { expect(tag).to respond_to(:media_type) }
  it { expect(tag).to delegate_method(:registry).to(:repository) }
  it { expect(tag).to delegate_method(:client).to(:repository) }

  describe '#path' do
    context 'when tag belongs to zero-level repository' do
      it 'returns path to the image' do
        expect(tag.path).to eq('group/test:tag')
      end
    end

    context 'when tag belongs to first-level repository' do
      let(:repository) do
        create(:container_repository, name: 'my_image', tags: %w[tag], project: project)
      end

      it 'returns path to the image' do
        expect(tag.path).to eq('group/test/my_image:tag')
      end
    end
  end

  describe '#location' do
    it 'returns a full location of the tag' do
      expect(tag.location)
        .to eq 'registry.gitlab/group/test:tag'
    end
  end

  context 'for manifest processing' do
    shared_examples 'using the value manually set on created_at' do
      let(:value) { 5.seconds.ago }

      before do
        tag.created_at = value
      end

      it 'does not use the config' do
        expect(tag).not_to receive(:config)

        expect(subject).to eq(value)
      end
    end

    describe '#total_size' do
      context 'when total_size is set' do
        before do
          tag.total_size = 1000
        end

        it 'returns the set size' do
          expect(tag.total_size).to eq(1000)
        end
      end
    end

    describe '#revision' do
      context 'when revision is set' do
        before do
          tag.revision = 'xyz789'
        end

        it 'returns the set revision' do
          expect(tag.revision).to eq('xyz789')
        end
      end

      context 'when revision is not set' do
        context 'when config_blob is not nil' do
          let(:blob) { ContainerRegistry::Blob.new(repository, {}) }

          before do
            allow(tag).to receive(:config_blob).and_return(blob)
            allow(blob).to receive(:revision).and_return('abc123')
          end

          it 'returns the revision from config_blob' do
            expect(tag.revision).to eq('abc123')
          end
        end

        context 'when config_blob is nil' do
          before do
            allow(tag).to receive(:config_blob).and_return(nil)
          end

          it 'returns nil' do
            expect(tag.revision).to be_nil
          end
        end
      end
    end

    describe '#short_revision' do
      context 'when revision is not nil' do
        before do
          allow(tag).to receive(:revision).and_return('abcdef1234567890')
        end

        it 'returns the first 9 characters of the revision' do
          expect(tag.short_revision).to eq('abcdef123')
        end
      end

      context 'when revision is nil' do
        before do
          allow(tag).to receive(:revision).and_return(nil)
        end

        it 'returns nil' do
          expect(tag.short_revision).to be_nil
        end
      end
    end

    describe 'valid?' do
      shared_examples 'checking for the manifest' do
        context 'when manifest is present' do
          before do
            allow(tag).to receive(:manifest).and_return('manifest')
          end

          it 'returns true' do
            expect(tag.valid?).to be(true)
          end
        end

        context 'when manifest is not present' do
          it 'returns false' do
            expect(tag.valid?).to be(false)
          end
        end
      end

      before do
        allow(tag).to receive(:manifest)
      end

      context 'when tag is instantiated with from_api: true' do
        let(:tag) { described_class.new(repository, 'tag', from_api: true) }

        it 'returns true' do
          expect(tag.valid?).to be(true)
          expect(tag).not_to have_received(:manifest)
        end
      end

      context 'when tag is instantiated with from_api: false' do
        let(:tag) { described_class.new(repository, 'tag', from_api: false) }

        it_behaves_like 'checking for the manifest'
      end

      context 'when tag is not instantiated from_api' do
        it_behaves_like 'checking for the manifest'
      end
    end

    context 'for schema v1' do
      before do
        stub_request(:get, 'http://registry.gitlab/v2/group/test/manifests/tag')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: File.read(Rails.root.join('spec/fixtures/container_registry/tag_manifest_1.json').to_s),
            headers: { 'Content-Type' => 'application/vnd.docker.distribution.manifest.v1+prettyjws' })
      end

      describe '#layers' do
        subject { tag.layers.length }

        it { is_expected.to eq(1) }
      end

      describe '#total_size' do
        subject { tag.total_size }

        it { is_expected.to be_nil }
      end

      context 'for config processing' do
        describe '#config' do
          subject { tag.config }

          it { is_expected.to be_nil }
        end

        describe '#created_at' do
          subject { tag.created_at }

          it { is_expected.to be_nil }

          it_behaves_like 'using the value manually set on created_at'
        end
      end
    end

    context 'when image is a helm chart' do
      before do
        stub_request(:get, 'http://registry.gitlab/v2/group/test/manifests/tag')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: File.read(Rails.root.join('spec/fixtures/container_registry/tag_manifest_helm.json').to_s),
            headers: { 'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json' })

        stub_request(:get, 'http://registry.gitlab/v2/group/test/blobs/sha256:65a07b841ece031e6d0ec5eb948eacb17aa6d7294cdeb01d5348e86242951487')
          .with(headers: { 'Accept' => 'application/vnd.cncf.helm.config.v1+json' })
          .to_return(
            status: 200,
            body: File.read(Rails.root.join('spec/fixtures/container_registry/config_blob_helm.json').to_s))
      end

      describe '#created_at' do
        subject { tag.created_at }

        it { is_expected.to be_nil }

        it_behaves_like 'using the value manually set on created_at'
      end
    end

    context 'for schema v2' do
      before do
        stub_request(:get, 'http://registry.gitlab/v2/group/test/manifests/tag')
          .with(headers: headers)
          .to_return(
            status: 200,
            body: File.read(Rails.root.join('spec/fixtures/container_registry/tag_manifest.json').to_s),
            headers: { 'Content-Type' => 'application/vnd.docker.distribution.manifest.v2+json' })
      end

      describe '#layers' do
        subject { tag.layers.length }

        it { is_expected.to eq(1) }
      end

      describe '#total_size' do
        subject { tag.total_size }

        it { is_expected.to eq(2319870) }
      end

      context 'for config processing' do
        shared_examples 'a processable' do
          describe '#config' do
            subject { tag.config }

            it { is_expected.not_to be_nil }
          end

          describe '#created_at' do
            subject { tag.created_at }

            it { is_expected.not_to be_nil }

            it_behaves_like 'using the value manually set on created_at'
          end
        end

        context 'when locally stored' do
          before do
            stub_request(:get, 'http://registry.gitlab/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac')
              .with(headers: { 'Accept' => 'application/octet-stream' })
              .to_return(
                status: 200,
                body: File.read(Rails.root.join('spec/fixtures/container_registry/config_blob.json').to_s))
          end

          it_behaves_like 'a processable'
        end

        context 'when externally stored' do
          before do
            stub_request(:get, 'http://registry.gitlab/v2/group/test/blobs/sha256:d7a513a663c1a6dcdba9ed832ca53c02ac2af0c333322cd6ca92936d1d9917ac')
              .with(headers: { 'Accept' => 'application/octet-stream' })
              .to_return(
                status: 307,
                headers: { 'Location' => 'http://external.com/blob/file' })

            stub_request(:get, 'http://external.com/blob/file')
              .to_return(
                status: 200,
                body: File.read(Rails.root.join('spec/fixtures/container_registry/config_blob.json').to_s))
          end

          it_behaves_like 'a processable'
        end

        describe '#force_created_at_from_iso8601' do
          subject { tag.force_created_at_from_iso8601(input) }

          shared_examples 'setting and caching the created_at value' do
            it 'sets and caches the created_at value' do
              expect(tag).not_to receive(:config)

              subject

              expect(tag.created_at).to eq(expected_value)
            end
          end

          context 'with a valid input' do
            let(:input) { 2.days.ago.iso8601 }
            let(:expected_value) { DateTime.iso8601(input) }

            it_behaves_like 'setting and caching the created_at value'
          end

          context 'with a nil input' do
            let(:input) { nil }
            let(:expected_value) { nil }

            it_behaves_like 'setting and caching the created_at value'
          end

          context 'with an invalid input' do
            let(:input) { 'not a timestamp' }
            let(:expected_value) { nil }

            it_behaves_like 'setting and caching the created_at value'
          end
        end

        describe 'updated_at=' do
          subject do
            tag.updated_at = input
            tag.updated_at
          end

          context 'with a valid input' do
            let(:input) { 2.days.ago.iso8601 }

            it { is_expected.to eq(DateTime.iso8601(input)) }
          end

          context 'with a nil input' do
            let(:input) { nil }

            it { is_expected.to be_nil }
          end

          context 'with an invalid input' do
            let(:input) { 'not a timestamp' }

            it { is_expected.to be_nil }
          end
        end

        describe 'published_at=' do
          subject do
            tag.published_at = input
            tag.published_at
          end

          context 'with a valid input' do
            let(:input) { 2.days.ago.iso8601 }

            it { is_expected.to eq(DateTime.iso8601(input)) }
          end

          context 'with a nil input' do
            let(:input) { nil }

            it { is_expected.to be_nil }
          end

          context 'with an invalid input' do
            let(:input) { 'not a timestamp' }

            it { is_expected.to be_nil }
          end
        end
      end
    end
  end

  context 'with stubbed digest' do
    before do
      stub_request(:head, 'http://registry.gitlab/v2/group/test/manifests/tag')
        .with(headers: headers)
        .to_return(status: 200, headers: { DependencyProxy::Manifest::DIGEST_HEADER => 'sha256:digest' })
    end

    describe '#digest' do
      context 'when manifest_digest is set' do
        before do
          tag.manifest_digest = 'sha256:manifestdigest'
        end

        it 'returns the set manifest_digest' do
          expect(tag.digest).to eq('sha256:manifestdigest')
        end
      end

      it 'returns a correct tag digest' do
        expect(tag.digest).to eq 'sha256:digest'
      end
    end

    describe '#unsafe_delete' do
      before do
        stub_request(:delete, 'http://registry.gitlab/v2/group/test/manifests/sha256:digest')
          .with(headers: headers)
          .to_return(status: 200)
      end

      it 'correctly deletes the tag' do
        expect(tag.unsafe_delete).to be_truthy
      end
    end

    describe '#protection_rule' do
      subject { tag.protection_rule }

      context 'when the project has protection rules' do
        before_all do
          create(
            :container_registry_protection_tag_rule,
            project: project,
            tag_name_pattern: 'tag',
            minimum_access_level_for_push: Gitlab::Access::MAINTAINER,
            minimum_access_level_for_delete: Gitlab::Access::OWNER
          )

          create(
            :container_registry_protection_tag_rule,
            project: project,
            tag_name_pattern: 'ta',
            minimum_access_level_for_push: Gitlab::Access::OWNER,
            minimum_access_level_for_delete: Gitlab::Access::MAINTAINER
          )

          create(
            :container_registry_protection_tag_rule,
            project: project,
            tag_name_pattern: 'non-matching-pattern',
            minimum_access_level_for_push: Gitlab::Access::ADMIN,
            minimum_access_level_for_delete: Gitlab::Access::ADMIN
          )

          create(
            :container_registry_protection_tag_rule,
            project: project,
            tag_name_pattern: 'sample',
            minimum_access_level_for_push: nil,
            minimum_access_level_for_delete: nil
          )
        end

        it 'returns the highest access level from the matching protection rules' do
          is_expected.to have_attributes(
            minimum_access_level_for_push: 'owner',
            minimum_access_level_for_delete: 'owner'
          )
        end

        context 'when there are no protection rules that match the tag name' do
          let(:tag) { described_class.new(repository, 'newname') }

          it { is_expected.to be_nil }
        end

        context 'when there are matching immutable rules' do
          let(:tag) { described_class.new(repository, 'sample') }

          it 'returns a matching immutable rule' do
            is_expected.to have_attributes(
              tag_name_pattern: 'sample',
              minimum_access_level_for_push: nil,
              minimum_access_level_for_delete: nil
            )
          end

          context 'when the feature container_registry_immutable_tags is disabled' do
            before do
              stub_feature_flags(container_registry_immutable_tags: false)
            end

            it { is_expected.to be_nil }
          end
        end
      end

      context 'when the project has no protection rules' do
        it { is_expected.to be_nil }
      end
    end

    describe '#protected_for_delete?' do
      subject { tag.protected_for_delete?(user) }

      let_it_be(:user) { create(:user) }
      let_it_be(:protection_rule) do
        create(
          :container_registry_protection_tag_rule,
          project: project,
          tag_name_pattern: 'tag',
          minimum_access_level_for_delete: Gitlab::Access::OWNER
        )
      end

      context 'when there is an immutable tag rule' do
        before do
          allow(tag).to receive(:immutable_protection_rule).and_return(
            build(:container_registry_protection_tag_rule, :immutable)
          )
        end

        it { is_expected.to be_truthy }
      end

      context 'when there is no protection rule' do
        before do
          allow(tag).to receive(:protection_rule).and_return(nil)
        end

        it { is_expected.to be_falsey }
      end

      context 'for admin' do
        before do
          allow(user).to receive(:can_admin_all_resources?).and_return(true)
        end

        it { is_expected.to be_falsey }
      end

      context 'when user has lower access level' do
        before_all do
          project.add_maintainer(user)
        end

        it { is_expected.to be_truthy }
      end

      context 'when user has the same or higher access level' do
        before_all do
          project.add_owner(user)
        end

        it { is_expected.to be_falsey }
      end

      context 'when user is nil' do
        let_it_be(:user) { nil }

        it { is_expected.to be_truthy }
      end
    end
  end
end
