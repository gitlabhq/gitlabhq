require 'spec_helper'

describe Groups::CreateService, services: true do
  let(:user) { create(:user) }

  let(:params) do
    { path: 'group_path', visibility_level: Gitlab::VisibilityLevel::PUBLIC }
  end

  describe '#execute' do
    subject(:service) { described_class.new(user, params) }

    it 'create groups without restricted visibility level' do
      group = service.execute

      expect(group).to be_persisted
    end

    it 'cannot create group with restricted visibility level' do
      allow_any_instance_of(ApplicationSetting).to receive(:restricted_visibility_levels).and_return([Gitlab::VisibilityLevel::PUBLIC])

      group = service.execute

      expect(group).not_to be_persisted
    end

    it 'delegates the label replication to Labels::ReplicateService' do
      expect_any_instance_of(Labels::ReplicateService).to receive(:execute).once

      service.execute
    end
  end
end
