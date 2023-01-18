# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequest::ApprovalRemovalSettings, :with_license do
  describe 'validations' do
    let(:reset_approvals_on_push) {}
    let(:selective_code_owner_removals) {}

    subject { described_class.new(project, reset_approvals_on_push, selective_code_owner_removals) }

    context 'when enabling selective_code_owner_removals and reset_approvals_on_push is disabled' do
      let(:project) { create(:project, reset_approvals_on_push: false) }
      let(:selective_code_owner_removals) { true }

      it { is_expected.to be_valid }
    end

    context 'when enabling selective_code_owner_removals and reset_approvals_on_push is enabled' do
      let(:project) { create(:project) }
      let(:selective_code_owner_removals) { true }

      it { is_expected.not_to be_valid }
    end

    context 'when enabling reset_approvals_on_push and selective_code_owner_removals is disabled' do
      let(:project) { create(:project) }
      let(:reset_approvals_on_push) { true }

      it { is_expected.to be_valid }
    end

    context 'when enabling reset_approvals_on_push and selective_code_owner_removals is enabled' do
      let(:project) { create(:project) }
      let(:reset_approvals_on_push) { true }

      before do
        project.project_setting.update!(selective_code_owner_removals: true)
      end

      it { is_expected.not_to be_valid }
    end

    context 'when enabling reset_approvals_on_push and selective_code_owner_removals' do
      let(:project) { create(:project) }
      let(:reset_approvals_on_push) { true }
      let(:selective_code_owner_removals) { true }

      it { is_expected.not_to be_valid }
    end
  end
end
