# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::ContainerRepository::ThirdParty::DeleteTagsService, feature_category: :container_registry do
  include_context 'container repository delete tags service shared context'

  let(:service) { described_class.new(repository, tags) }

  describe '#execute' do
    let(:tags) { %w[A Ba] }

    subject { service.execute }

    context 'with tags to delete' do
      it 'deletes the tags by name' do
        stub_upload('sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

        tags.each { |tag| stub_put_manifest_request(tag) }

        expect_delete_tags(['sha256:dummy'])

        is_expected.to eq(status: :success, deleted: tags)
      end

      it 'succeeds when tag delete returns 404' do
        stub_upload('sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

        stub_put_manifest_request('A')
        stub_put_manifest_request('Ba')

        stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/manifests/sha256:dummy")
          .to_return(status: 404, body: '', headers: {})

        is_expected.to eq(status: :success, deleted: tags)
      end

      context 'with failures' do
        context 'when the dummy manifest generation fails' do
          before do
            stub_upload('sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3', success: false)
          end

          it { is_expected.to eq(status: :error, message: 'could not generate manifest') }
        end

        context 'when updating tags fails' do
          before do
            stub_upload('sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3')

            stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/manifests/sha256:4435000728ee66e6a80e55637fc22725c256b61de344a2ecdeaac6bdb36e8bc3")
              .to_return(status: 200, body: '', headers: {})
          end

          context 'all tag updates fail' do
            before do
              stub_put_manifest_request('A', 500, {})
              stub_put_manifest_request('Ba', 500, {})
            end

            it { is_expected.to eq(status: :error, message: "could not delete tags: #{tags.join(', ')}") }

            context 'when a large list of tag updates fails' do
              let(:tags) { Array.new(1000) { |i| "tag_#{i}" } }

              before do
                expect(service).to receive(:replace_tag_manifests).and_return({})
              end

              it 'truncates the log message' do
                expect(subject).to eq(status: :error, message: "could not delete tags: #{tags.join(', ')}".truncate(1000))
              end
            end
          end

          context 'a single tag update fails' do
            before do
              stub_put_manifest_request('A')
              stub_put_manifest_request('Ba', 500, {})

              stub_request(:delete, "http://registry.gitlab/v2/#{repository.path}/manifests/sha256:dummy")
                .to_return(status: 404, body: '', headers: {})
            end

            it { is_expected.to eq(status: :success, deleted: ['A']) }
          end
        end
      end
    end

    context 'with empty tags' do
      let_it_be(:tags) { [] }

      it 'does not remove anything' do
        expect_any_instance_of(ContainerRegistry::Client).not_to receive(:delete_repository_tag_by_digest)

        is_expected.to eq(status: :success, deleted: [])
      end
    end
  end
end
