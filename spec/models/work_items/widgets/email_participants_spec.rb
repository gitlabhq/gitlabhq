# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::Widgets::EmailParticipants, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }
  let_it_be(:email_participant) { create(:issue_email_participant, issue: work_item) }

  describe '.type' do
    subject { described_class.type }

    it { is_expected.to eq(:email_participants) }
  end

  describe '.quick_action_commands' do
    subject { described_class.quick_action_commands }

    it { is_expected.to contain_exactly(:add_email, :remove_email) }
  end

  describe '.quick_action_params' do
    subject { described_class.quick_action_params }

    it { is_expected.to include(:emails) }
  end

  describe '#type' do
    subject { described_class.new(work_item).type }

    it { is_expected.to eq(:email_participants) }
  end

  describe '#issue_email_participants' do
    subject { described_class.new(work_item).issue_email_participants }

    it { is_expected.to match_array(work_item.issue_email_participants) }
  end
end
