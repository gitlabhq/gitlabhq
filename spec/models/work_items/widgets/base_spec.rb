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

  describe '#widget_definition' do
    let(:widget_definition) { build(:widget_definition) }

    subject { described_class.new(work_item, widget_definition: widget_definition).widget_definition }

    it { is_expected.to eq(widget_definition) }
  end

  describe '.process_quick_action_param' do
    subject { described_class.process_quick_action_param(:label_ids, [1, 2]) }

    it { is_expected.to eq({ label_ids: [1, 2] }) }
  end

  describe 'non-existent callback class' do
    it "returns nil" do
      allow(::WorkItems::DataSync::Widgets).to receive(:const_get).with(
        "Assignees", false
      ).and_raise(NameError)

      expect(WorkItems::Widgets::Assignees.new(work_item).sync_data_callback_class).to be_nil
    end
  end
end
