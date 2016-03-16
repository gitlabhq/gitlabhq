require 'spec_helper'

describe Groups::CreateService, services: true do
    let!(:user)    { create(:user) }
    let!(:private_group)    { create(:group, visibility_level: Gitlab::VisibilityLevel::PRIVATE) }
    let!(:internal_group)   { create(:group, visibility_level: Gitlab::VisibilityLevel::INTERNAL) }
    let!(:public_group)     { create(:group, visibility_level: Gitlab::VisibilityLevel::PUBLIC) }

  describe "execute" do
    let!(:service) { described_class.new(public_group, user, visibility_level: Gitlab::VisibilityLevel::PUBLIC ) }
    subject { service.execute }

    context "create groups without restricted visibility level" do
      it { is_expected.to be_truthy }
    end

    context "cannot create group with restricted visibility level" do
      before { allow(current_application_settings).to receive(:restricted_visibility_levels).and_return([Gitlab::VisibilityLevel::PUBLIC]) }
      it { is_expected.to be_falsy }
    end
  end
end
