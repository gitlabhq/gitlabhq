require 'spec_helper'

describe Groups::CreateService, services: true do
  let!(:user)         { create(:user) }
  let!(:group_params) { { path: "group_path", visibility_level: Gitlab::VisibilityLevel::PUBLIC } }

  describe "execute" do
    let!(:service) { described_class.new(user, group_params ) }
    subject { service.execute }

    context "create groups without restricted visibility level" do
      it { is_expected.to be_persisted }
    end

    context "cannot create group with restricted visibility level" do
      before { allow_any_instance_of(ApplicationSetting).to receive(:restricted_visibility_levels).and_return([Gitlab::VisibilityLevel::PUBLIC]) }
      it { is_expected.not_to be_persisted }
    end
  end
end
