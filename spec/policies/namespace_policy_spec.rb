require 'spec_helper'

describe NamespacePolicy do
  let(:current_user) { create(:user) }
  let(:namespace) { current_user.namespace }

  subject { described_class.new(current_user, namespace) }

  context "create projects" do
    context "user namespace" do
      it { is_expected.to be_allowed(:create_projects) }
    end

    context "user who has exceeded project limit" do
      let(:current_user) { create(:user, projects_limit: 0) }

      it { is_expected.not_to be_allowed(:create_projects) }
    end
  end
end
