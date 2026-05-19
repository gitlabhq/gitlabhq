# frozen_string_literal: true

RSpec.shared_examples 'subgroup/project-provisioned service account restriction' do |ability|
  context 'when service account is provisioned by a subgroup' do
    before do
      allow(service_account).to receive_messages(sa_provisioned_by_subgroup?: true, sa_provisioned_by_project?: false)
    end

    it { is_expected.to be_disallowed(ability) }
  end

  context 'when service account is provisioned by a project' do
    before do
      allow(service_account).to receive_messages(sa_provisioned_by_subgroup?: false, sa_provisioned_by_project?: true)
    end

    it { is_expected.to be_disallowed(ability) }
  end

  context 'when service account is provisioned by a top-level group or has no provisioning source' do
    before do
      allow(service_account).to receive_messages(sa_provisioned_by_subgroup?: false, sa_provisioned_by_project?: false)
    end

    it { is_expected.to be_allowed(ability) }
  end
end
