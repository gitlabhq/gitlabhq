# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::InviteTeam do
  let_it_be(:group) { build(:group) }
  let_it_be(:user) { build(:user) }

  let(:series) { 0 }

  subject(:message) { described_class.new(group: group, user: user, series: series) }

  describe 'initialize' do
    context 'when series is valid' do
      it 'does not raise error' do
        expect { subject }.not_to raise_error(ArgumentError)
      end
    end

    context 'when series is invalid' do
      let(:series) { 1 }

      it 'raises error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end
  end

  it 'contains the correct message', :aggregate_failures do
    expect(message.subject_line).to eq 'Invite your teammates to GitLab'
    expect(message.tagline).to be_empty
    expect(message.title).to eq 'GitLab is better with teammates to help out!'
    expect(message.subtitle).to be_empty
    expect(message.body_line1).to eq 'Invite your teammates today and build better code together. You can even assign tasks to new teammates such as setting up CI/CD, to help get projects up and running.'
    expect(message.body_line2).to be_empty
    expect(message.cta_text).to eq 'Invite your teammates to help'
    expect(message.logo_path).to eq 'mailers/in_product_marketing/team-0.png'
  end
end
