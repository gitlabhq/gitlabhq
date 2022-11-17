# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::Milestone do
  let_it_be(:project) { create(:project) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:work_item) { create(:work_item, :issue, project: project, milestone: milestone) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:milestone) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:milestone) }
  end

  describe '#milestone' do
    subject { described_class.new(work_item).milestone }

    it { is_expected.to eq(work_item.milestone) }
  end
end
