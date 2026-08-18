# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Organizations::TransferTopicAvatarWorker, feature_category: :organization do
  let_it_be(:old_organization) { create(:organization) }
  let_it_be(:new_organization) { create(:organization) }

  let(:worker) { described_class.new }

  describe '#perform' do
    subject(:perform) { worker.perform(source_topic_id, target_topic_id) }

    context 'when source topic has an avatar' do
      let_it_be(:source_topic) do
        create(:topic, :with_avatar, organization: old_organization)
      end

      let_it_be(:target_topic) do
        create(:topic, organization: new_organization, name: source_topic.name, slug: source_topic.slug)
      end

      let(:source_topic_id) { source_topic.id }
      let(:target_topic_id) { target_topic.id }

      it 'copies the avatar to the target topic' do
        expect(target_topic.avatar).not_to be_present

        perform

        target_topic.reload
        expect(target_topic.avatar).to be_present
      end
    end

    context 'when source topic does not have an avatar' do
      let_it_be(:source_topic) { create(:topic, organization: old_organization) }
      let_it_be(:target_topic) { create(:topic, organization: new_organization) }

      let(:source_topic_id) { source_topic.id }
      let(:target_topic_id) { target_topic.id }

      it 'does not modify the target topic' do
        expect { perform }.not_to change { target_topic.reload.avatar.present? }
      end
    end

    context 'when target topic already has an avatar' do
      let_it_be(:source_topic) do
        create(:topic, :with_avatar, organization: old_organization)
      end

      let_it_be(:target_topic) do
        create(:topic, :with_avatar, organization: new_organization)
      end

      let(:source_topic_id) { source_topic.id }
      let(:target_topic_id) { target_topic.id }

      it 'does not overwrite the existing avatar' do
        original_avatar = target_topic.avatar.url

        perform

        expect(target_topic.reload.avatar.url).to eq(original_avatar)
      end
    end

    context 'when source topic does not exist' do
      let(:source_topic_id) { non_existing_record_id }
      let(:target_topic_id) { create(:topic).id }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when target topic does not exist' do
      let(:source_topic_id) { create(:topic).id }
      let(:target_topic_id) { non_existing_record_id }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end
  end

  describe 'worker attributes' do
    it { is_expected.to be_a(ApplicationWorker) }

    it 'is idempotent' do
      expect(described_class).to be_idempotent
    end

    it 'has the correct feature category' do
      expect(described_class.get_feature_category).to eq(:organization)
    end

    it 'has low urgency' do
      expect(described_class.get_urgency).to eq(:low)
    end
  end
end
