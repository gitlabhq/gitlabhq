# frozen_string_literal: true

RSpec.shared_context 'with merge request approval settings' do
  let(:instance_prevents_author_approval) { false }
  let(:group_prevents_author_approval) { false }
  let(:project_prevents_author_approval) { false }
  let(:approval_policy_prevents_author_approval) { false }

  let(:instance_prevents_committer_approval) { false }
  let(:group_prevents_committer_approval) { false }
  let(:project_prevents_committer_approval) { false }
  let(:approval_policy_prevents_committer_approval) { false }

  let(:policy_read) do
    if approval_policy_prevents_author_approval && approval_policy_prevents_committer_approval
      create(:scan_result_policy_read,
        project_approval_settings: {
          prevent_approval_by_author: true,
          prevent_approval_by_commit_author: true
        })
    elsif approval_policy_prevents_author_approval
      create(:scan_result_policy_read, :prevent_approval_by_author)
    elsif approval_policy_prevents_committer_approval
      create(:scan_result_policy_read, :prevent_approval_by_commit_author)
    end
  end

  let_it_be(:group) { create(:group) }
  let_it_be_with_reload(:group_setting) { group.create_group_merge_request_approval_setting! }

  before do
    approval_rule_project.update!(group: group)

    Gitlab::CurrentSettings.update!(
      prevent_merge_requests_author_approval: instance_prevents_author_approval,
      prevent_merge_requests_committers_approval: instance_prevents_committer_approval
    )

    group_setting.update!(
      allow_author_approval: !group_prevents_author_approval,
      allow_committer_approval: !group_prevents_committer_approval
    )

    approval_rule_project.update!(
      merge_requests_author_approval: !project_prevents_author_approval,
      merge_requests_disable_committers_approval: project_prevents_committer_approval
    )

    rule.update!(scan_result_policy_read: policy_read) if policy_read
  end
end

RSpec.shared_examples 'approval rules filtering' do
  include_context 'with merge request approval settings'

  describe '#prevents_author_approval?' do
    subject(:prevents_author_approval) { rule.prevents_author_approval? }

    it { is_expected.to be(false) }

    context 'when instance prevents author approval' do
      let(:instance_prevents_author_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when parent group prevents author approval' do
      let(:group_prevents_author_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when target project prevents author approval' do
      let(:project_prevents_author_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when approval policy prevents author approval' do
      let(:approval_policy_prevents_author_approval) { true }

      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      it { is_expected.to be(true) }

      context 'without licensed feature' do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it { is_expected.to be(false) }
      end
    end
  end

  describe '#prevents_committer_approval?' do
    subject(:prevents_committer_approval) { rule.prevents_committer_approval? }

    it { is_expected.to be(false) }

    context 'when instance prevents committer approval' do
      let(:instance_prevents_committer_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when parent group prevents committer approval' do
      let(:group_prevents_committer_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when target project prevents committer approval' do
      let(:project_prevents_committer_approval) { true }

      it { is_expected.to be(true) }
    end

    context 'when approval policy prevents committer approval' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
      end

      let(:approval_policy_prevents_committer_approval) { true }

      it { is_expected.to be(true) }

      context 'without licensed feature' do
        before do
          stub_licensed_features(security_orchestration_policies: false)
        end

        it { is_expected.to be(false) }
      end
    end
  end
end
