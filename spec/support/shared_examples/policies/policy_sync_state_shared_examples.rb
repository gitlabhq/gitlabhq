# frozen_string_literal: true

RSpec.shared_context 'with policy sync state', :clean_gitlab_redis_shared_state do
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, :namespace) }

  let(:policy_configuration_id) { policy_configuration.id }
  let(:state) { Security::SecurityOrchestrationPolicies::PolicySyncState::State.new(policy_configuration_id) }

  before do
    allow(Gitlab::ApplicationContext).to receive(:current_context_attribute)
                                           .and_return(policy_configuration_id.to_s)
  end
end
