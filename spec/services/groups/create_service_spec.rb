require 'spec_helper'

describe Groups::CreateService, '#execute', services: true do
  let!(:user) { create(:user) }
  let!(:group_params) { { path: "group_path", visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

  describe 'visibility level restrictions' do
    let!(:service) { described_class.new(user, group_params) }

    subject { service.execute }

    context "create groups without restricted visibility level" do
      it { is_expected.to be_persisted }
    end

    context "cannot create group with restricted visibility level" do
      before { allow_any_instance_of(ApplicationSetting).to receive(:restricted_visibility_levels).and_return([Gitlab::VisibilityLevel::PUBLIC]) }

      it { is_expected.not_to be_persisted }
    end
  end

  describe 'creating subgroup' do
    let!(:group) { create(:group) }
    let!(:service) { described_class.new(user, group_params.merge(parent_id: group.id)) }

    subject { service.execute }

    context 'as group owner' do
      before { group.add_owner(user) }

      it { is_expected.to be_persisted }
    end

    context 'as guest' do
      it 'does not save group and returns an error' do
        is_expected.not_to be_persisted
        expect(subject.errors[:parent_id].first).to eq('manage access required to create subgroup')
        expect(subject.parent_id).to be_nil
      end
    end
  end

  context 'repository_size_limit assignment as Bytes' do
    let(:admin_user) { create(:user, admin: true) }
    let(:service) { described_class.new(admin_user, group_params.merge(opts)) }

    context 'when param present' do
      let(:opts) { { repository_size_limit: '100' } }

      it 'assign repository_size_limit as Bytes' do
        group = service.execute

        expect(group.repository_size_limit).to eql(100 * 1024 * 1024)
      end
    end

    context 'when param not present' do
      let(:opts) { { repository_size_limit: '' } }

      it 'assign nil value' do
        group = service.execute

        expect(group.repository_size_limit).to be_nil
      end
    end
  end
end
