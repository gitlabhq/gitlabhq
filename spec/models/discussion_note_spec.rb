# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiscussionNote do
  describe '#to_ability_name' do
    subject { described_class.new.to_ability_name }

    it { is_expected.to eq('note') }
  end

  describe 'validations' do
    context 'when noteable is an abuse report' do
      subject { build(:discussion_note, noteable: build_stubbed(:abuse_report)) }

      it { is_expected.to be_valid }
    end
  end
end
