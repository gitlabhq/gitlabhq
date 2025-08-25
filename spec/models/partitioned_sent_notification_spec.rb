# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PartitionedSentNotification, :request_store, feature_category: :shared do
  include SentNotificationHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :repository, group: group) }

  describe '.create' do
    it 'sets partition after saving the record' do
      sent_notification = create(:sent_notification, project: project)

      new = described_class.new(sent_notification.attributes.except('id').merge(reply_key: described_class.reply_key))

      expect { new.save! }.to change { new.partition }.from(nil).to(instance_of(Integer))
    end
  end

  describe '#partitioned_reply_key' do
    let_it_be(:sent_notification) { create_sent_notification(project: project) }

    subject { sent_notification.partitioned_reply_key }

    it { is_expected.to eq("#{sent_notification.partition.to_s(36)}-#{sent_notification.reply_key}") }

    context 'when sent_notification is not persisted' do
      let(:sent_notification) { build(:sent_notification) }

      it { is_expected.to eq(sent_notification.reply_key) }
    end
  end
end
