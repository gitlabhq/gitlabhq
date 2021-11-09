# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InviteTeamEmailWorker do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }

  it 'sends the email' do
    expect(Namespaces::InviteTeamEmailService).to receive(:send_email).with(user, group).once
    subject.perform(group.id, user.id)
  end

  context 'when user id is non-existent' do
    it 'does not send the email' do
      expect(Namespaces::InviteTeamEmailService).not_to receive(:send_email)
      subject.perform(group.id, non_existing_record_id)
    end
  end

  context 'when group id is non-existent' do
    it 'does not send the email' do
      expect(Namespaces::InviteTeamEmailService).not_to receive(:send_email)
      subject.perform(non_existing_record_id, user.id)
    end
  end
end
