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
end
