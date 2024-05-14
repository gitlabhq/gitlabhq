# frozen_string_literal: true
require "spec_helper"

RSpec.describe DesignManagement::DesignPolicy, feature_category: :portfolio_management do
  include DesignManagementTestHelpers

  let(:guest_design_abilities) { %i[read_design] }
  let(:reporter_design_abilities) { %i[create_design destroy_design move_design update_design] }
  let(:design_abilities) { guest_design_abilities + reporter_design_abilities }

  let_it_be(:guest) { create(:user) }
  let_it_be(:reporter) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let_it_be(:owner) { create(:user) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) do
    create(:project, :public, namespace: owner.namespace, guests: guest, maintainers: maintainer, developers: developer,
      reporters: reporter)
  end

  let_it_be(:issue) { create(:issue, project: project) }

  let(:design) { create(:design, issue: issue) }

  subject(:design_policy) { described_class.new(current_user, design) }

  shared_examples_for "design abilities not available" do
    context "for owners" do
      let(:current_user) { owner }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for admins" do
      let(:current_user) { admin }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for maintainers" do
      let(:current_user) { maintainer }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for developers" do
      let(:current_user) { developer }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for reporters" do
      let(:current_user) { reporter }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for guests" do
      let(:current_user) { guest }

      it { is_expected.to be_disallowed(*design_abilities) }
    end

    context "for anonymous users" do
      let(:current_user) { nil }

      it { is_expected.to be_disallowed(*design_abilities) }
    end
  end

  shared_examples_for "read-only design abilities" do
    it { is_expected.to be_allowed(*guest_design_abilities) }
    it { is_expected.to be_disallowed(*reporter_design_abilities) }
  end

  shared_examples_for "design abilities available for members" do
    context "for owners" do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*design_abilities) }
    end

    context "for admins" do
      let(:current_user) { admin }

      context "when admin mode enabled", :enable_admin_mode do
        it { is_expected.to be_allowed(*design_abilities) }
      end

      context "when admin mode disabled" do
        it_behaves_like "read-only design abilities"
      end
    end

    context "for maintainers" do
      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(*design_abilities) }
    end

    context "for developers" do
      let(:current_user) { developer }

      it { is_expected.to be_allowed(*design_abilities) }
    end

    context "for reporters" do
      let(:current_user) { reporter }

      it { is_expected.to be_allowed(*design_abilities) }
    end
  end

  context "when DesignManagement is not enabled" do
    before do
      enable_design_management(false)
    end

    it_behaves_like "design abilities not available"
  end

  context "when the feature is available" do
    before do
      enable_design_management
    end

    it_behaves_like "design abilities available for members"

    context "for guests in private projects" do
      let_it_be(:project) { create(:project, :private) }

      let(:current_user) { guest }

      it_behaves_like "read-only design abilities"
    end

    context "for anonymous users in public projects" do
      let(:current_user) { nil }

      it_behaves_like "read-only design abilities"
    end

    context "when the issue is confidential" do
      let_it_be(:issue) { create(:issue, :confidential, project: project) }

      it_behaves_like "design abilities available for members"

      context "for guests" do
        let(:current_user) { guest }

        it { is_expected.to be_disallowed(*design_abilities) }
      end

      context "for anonymous users" do
        let(:current_user) { nil }

        it { is_expected.to be_disallowed(*design_abilities) }
      end
    end

    context "when the project is archived" do
      let_it_be(:project) { create(:project, :public, :archived) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:current_user) { owner }

      it_behaves_like "read-only design abilities"
    end
  end
end
