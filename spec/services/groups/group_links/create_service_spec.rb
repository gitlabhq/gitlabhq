require 'spec_helper'

describe Groups::GroupLinks::CreateService, '#execute' do
  let(:user) { create :user }
  let(:group) { create :group }
  let(:shared_group) { create :group }
  let(:opts) do
    {
        shared_group_access: Gitlab::Access::DEVELOPER,
        expires_at: nil
    }
  end
  let(:subject) { described_class.new(group, user, opts) }

  it 'adds group to another group' do
    expect { subject.execute(group) }.to change { group.group_group_links.count }.from(0).to(1)
  end

  it 'returns false if shared group is blank' do
    expect { subject.execute(nil) }.not_to change { group.group_group_links.count }
  end
end
