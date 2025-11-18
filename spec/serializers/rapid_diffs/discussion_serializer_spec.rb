# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapidDiffs::DiscussionSerializer, feature_category: :source_code_management do
  let_it_be(:user) { build_stubbed(:user) }
  let_it_be(:project) { build_stubbed(:project, :repository) }

  let(:serializer) { described_class.new(current_user: user, project: project) }

  describe '#with_additional_opts' do
    let(:base_opts) { { some_option: 'value' } }
    let(:serializer_instance) { described_class.new(current_user: user, project: project) }

    before do
      allow(Gitlab::SubmoduleLinks).to receive(:new).and_call_original
    end

    it 'merges submodule_links into the options' do
      result = serializer_instance.send(:with_additional_opts, base_opts)

      expect(result).to include(some_option: 'value')
      expect(result).to have_key(:submodule_links)
      expect(result[:submodule_links]).to be_a(Gitlab::SubmoduleLinks)
    end

    it 'creates submodule_links with project repository' do
      serializer_instance.send(:with_additional_opts, base_opts)

      expect(Gitlab::SubmoduleLinks).to have_received(:new).with(project.repository)
    end

    context 'when options already contain submodule_links' do
      let(:existing_submodule_links) { instance_double(Gitlab::SubmoduleLinks) }
      let(:base_opts) { { submodule_links: existing_submodule_links } }

      it 'overrides existing submodule_links' do
        result = serializer_instance.send(:with_additional_opts, base_opts)

        expect(result[:submodule_links]).not_to eq(existing_submodule_links)
        expect(result[:submodule_links]).to be_a(Gitlab::SubmoduleLinks)
      end
    end
  end

  describe '#represent' do
    let(:discussion) { instance_double(Discussion, id: 1, reply_id: 'reply-1') }
    let(:entity_instance) { instance_double(RapidDiffs::DiscussionEntity) }
    let(:expected_result) { { 'id' => 1, 'reply_id' => 'reply-1' } }

    before do
      allow(RapidDiffs::DiscussionEntity).to receive(:represent).and_return(expected_result)
      allow(Gitlab::SubmoduleLinks).to receive(:new).and_call_original
    end

    it 'calls the entity with additional options including submodule_links' do
      result = serializer.represent(discussion)

      expect(RapidDiffs::DiscussionEntity).to have_received(:represent).with(
        discussion,
        hash_including(
          submodule_links: an_instance_of(Gitlab::SubmoduleLinks)
        )
      )
      expect(result).to eq(expected_result)
    end

    it 'passes submodule_links created from project repository' do
      serializer.represent(discussion)

      expect(Gitlab::SubmoduleLinks).to have_received(:new).with(project.repository).at_least(:once)
    end

    context 'when additional options are provided' do
      let(:additional_opts) { { custom_option: 'custom_value' } }

      it 'merges additional options with submodule_links' do
        serializer.represent(discussion, additional_opts)

        expect(RapidDiffs::DiscussionEntity).to have_received(:represent).with(
          discussion,
          hash_including(
            custom_option: 'custom_value',
            submodule_links: an_instance_of(Gitlab::SubmoduleLinks)
          )
        )
      end
    end

    context 'when project repository is nil' do
      before do
        allow(project).to receive(:repository).and_return(nil)
      end

      it 'handles nil repository gracefully' do
        expect { serializer.represent(discussion) }.not_to raise_error
        expect(Gitlab::SubmoduleLinks).to have_received(:new).with(nil).at_least(:once)
      end
    end

    context 'with multiple discussions' do
      let(:discussions) { [discussion, instance_double(Discussion, id: 2, reply_id: 'reply-2')] }
      let(:expected_results) { [{ 'id' => 1 }, { 'id' => 2 }] }

      before do
        allow(RapidDiffs::DiscussionEntity).to receive(:represent).and_return(expected_results)
      end

      it 'serializes multiple discussions' do
        result = serializer.represent(discussions)

        expect(result).to eq(expected_results)
        expect(RapidDiffs::DiscussionEntity).to have_received(:represent).with(
          discussions,
          hash_including(submodule_links: an_instance_of(Gitlab::SubmoduleLinks))
        )
      end
    end

    context 'when discussion is nil' do
      it 'handles nil discussion' do
        serializer.represent(nil)
        expect(RapidDiffs::DiscussionEntity).to have_received(:represent).with(
          nil,
          hash_including(submodule_links: an_instance_of(Gitlab::SubmoduleLinks))
        )
      end
    end
  end
end
