# frozen_string_literal: true

require 'spec_helper'

describe Projects::GroupLinks::UpdateService, '#execute' do
  let_it_be(:user) { create :user }
  let_it_be(:group) { create :group }
  let_it_be(:project) { create :project }
  let!(:link) { create(:project_group_link, project: project, group: group) }

  let(:expiry_date) { 1.month.from_now.to_date }
  let(:group_link_params) do
    { group_access: Gitlab::Access::GUEST,
      expires_at: expiry_date }
  end

  subject { described_class.new(link).execute(group_link_params) }

  before do
    group.add_developer(user)
  end

  it 'updates existing link' do
    expect(link.group_access).to eq(Gitlab::Access::DEVELOPER)
    expect(link.expires_at).to be_nil

    subject

    link.reload

    expect(link.group_access).to eq(Gitlab::Access::GUEST)
    expect(link.expires_at).to eq(expiry_date)
  end

  it 'updates project permissions' do
    expect { subject }.to change { user.can?(:create_release, project) }.from(true).to(false)
  end

  it 'executes UserProjectAccessChangedService' do
    expect_next_instance_of(UserProjectAccessChangedService) do |service|
      expect(service).to receive(:execute)
    end

    subject
  end

  context 'with only param not requiring authorization refresh' do
    let(:group_link_params) { { expires_at: Date.tomorrow } }

    it 'does not execute UserProjectAccessChangedService' do
      expect(UserProjectAccessChangedService).not_to receive(:new)

      subject
    end
  end
end
