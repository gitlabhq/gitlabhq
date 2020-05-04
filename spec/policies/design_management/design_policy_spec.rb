# frozen_string_literal: true
require 'spec_helper'

describe DesignManagement::DesignPolicy do
  include DesignManagementTestHelpers

  include_context 'ProjectPolicy context'

  let(:guest_design_abilities) { %i[read_design] }
  let(:developer_design_abilities) do
    %i[create_design destroy_design]
  end
  let(:design_abilities) { guest_design_abilities + developer_design_abilities }

  let(:issue) { create(:issue, project: project) }
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

  shared_examples_for "design abilities available for members" do
    context "for owners" do
      let(:current_user) { owner }

      it { is_expected.to be_allowed(*design_abilities) }
    end

    context "for admins" do
      let(:current_user) { admin }

      it { is_expected.to be_allowed(*design_abilities) }
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

      it { is_expected.to be_allowed(*guest_design_abilities) }
      it { is_expected.to be_disallowed(*developer_design_abilities) }
    end
  end

  shared_examples_for "read-only design abilities" do
    it { is_expected.to be_allowed(:read_design) }
    it { is_expected.to be_disallowed(:create_design, :destroy_design) }
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
      let(:project) { create(:project, :private) }
      let(:current_user) { guest }

      it { is_expected.to be_allowed(*guest_design_abilities) }
      it { is_expected.to be_disallowed(*developer_design_abilities) }
    end

    context "for anonymous users in public projects" do
      let(:current_user) { nil }

      it { is_expected.to be_allowed(*guest_design_abilities) }
      it { is_expected.to be_disallowed(*developer_design_abilities) }
    end

    context "when the issue is confidential" do
      let(:issue) { create(:issue, :confidential, project: project) }

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

    context "when the issue is locked" do
      let(:current_user) { owner }
      let(:issue) { create(:issue, :locked, project: project) }

      it_behaves_like "read-only design abilities"
    end

    context "when the issue has moved" do
      let(:current_user) { owner }
      let(:issue) { create(:issue, project: project, moved_to: create(:issue)) }

      it_behaves_like "read-only design abilities"
    end

    context "when the project is archived" do
      let(:current_user) { owner }

      before do
        project.update!(archived: true)
      end

      it_behaves_like "read-only design abilities"
    end
  end
end
