# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Base do
  let_it_be(:work_item) { create(:work_item, description: '# Title') }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:base) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:base) }
  end

  describe '.process_quick_action_param' do
    subject { described_class.process_quick_action_param(:label_ids, [1, 2]) }

    it { is_expected.to eq({ label_ids: [1, 2] }) }
  end
end
