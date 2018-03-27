require 'spec_helper'

describe NotificationRecipient do
  let(:user) { create(:user) }
  let(:project) { create(:project, namespace: user.namespace) }
  let(:target) { create(:issue, project: project) }

  subject(:recipient) { described_class.new(user, :watch, target: target, project: project) }

  it 'denies access to a target when cross project access is denied' do
    allow(Ability).to receive(:allowed?).and_call_original
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project, :global).and_return(false)

    expect(recipient.has_access?).to be_falsy
  end
end
