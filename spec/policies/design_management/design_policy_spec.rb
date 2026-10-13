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
  let_it_be(:project) do
    create(:project, :public, namespace: owner.namespace, guests: guest, maintainers: maintainer, developers: developer,
      reporters: reporter)
  end

  let_it_be(:issue) { create(:issue, project: project) }

  let(:design) { create(:design, issue: issue) }

  subject(:design_policy) { described_class.new(current_user, design) }

  it { expect(described_class.new(guest, design)).to delegate_to(IssuePolicy) }

  context "when the feature is available" do
    before do
      enable_design_management
    end

    context "when the issue is confidential" do
      let_it_be(:issue) { create(:issue, :confidential, project: project) }

      context "for reporters" do
        let(:current_user) { reporter }

        it { is_expected.to be_allowed(*design_abilities) }
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

    context "when the project is archived" do
      let_it_be(:project) { create(:project, :public, :archived, maintainers: maintainer) }
      let_it_be(:issue) { create(:issue, project: project) }

      let(:current_user) { maintainer }

      it { is_expected.to be_allowed(*guest_design_abilities) }
      it { is_expected.to be_disallowed(:create_design, :destroy_design, :update_design) }
    end
  end
end
