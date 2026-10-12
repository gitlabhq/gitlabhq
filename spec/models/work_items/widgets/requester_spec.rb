# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Requester, feature_category: :service_desk do
  let_it_be(:support_bot) { create(:support_bot) }

  describe '.type' do
    it { expect(described_class.type).to eq(:requester) }
  end

  describe '#type' do
    it { expect(described_class.new(build(:work_item, :ticket)).type).to eq(:requester) }
  end

  context 'when the ticket was created through Service Desk' do
    let(:work_item) do
      build(:work_item, :ticket, author: support_bot, service_desk_reply_to: 'requester@example.com')
    end

    subject(:widget) { described_class.new(work_item) }

    it 'returns the external email' do
      expect(widget.email).to eq('requester@example.com')
    end
  end
end
