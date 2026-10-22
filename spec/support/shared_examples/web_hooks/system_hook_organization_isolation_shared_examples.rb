# frozen_string_literal: true

# `web_hooks` has more than one sharding key, so data isolation does not scope it and every
# system hook read path must filter by organization itself. Each example creates a hook in
# `organization`, which the caller defines, and a hook in `other_organization`.

# Define `execute_system_hooks` to run the code path that delivers system hooks.
RSpec.shared_examples 'system hook delivery scoped to the organization' do |hook_attributes: {}|
  let(:other_organization) { create(:organization) } unless method_defined?(:other_organization)
  let!(:other_organization_hook) { create(:system_hook, organization: other_organization, **hook_attributes) }
  let!(:organization_hook) { create(:system_hook, organization: organization, **hook_attributes) }

  before do
    allow(WebHookWorker).to receive(:perform_async)
    allow(Gitlab::FileHook).to receive(:execute_all_async)
  end

  it 'queues only the hooks of the organization', :aggregate_failures do
    expect { execute_system_hooks }.not_to query_system_hooks_without_organization_id

    expect(WebHookWorker).to have_received(:perform_async).with(organization_hook.id, any_args).once
    expect(WebHookWorker).not_to have_received(:perform_async).with(other_organization_hook.id, any_args)
  end

  context 'when the organization has no system hooks' do
    let!(:organization_hook) { nil }

    it 'does not queue hooks of other organizations' do
      execute_system_hooks

      expect(WebHookWorker).not_to have_received(:perform_async).with(other_organization_hook.id, any_args)
    end
  end
end

# Define `system_hooks_active?` to run the check and return its result. The result can be
# memoized on the record, so the caller should check a fresh record in each example.
RSpec.shared_examples 'system hook presence check scoped to the organization' do |hook_attributes: {}|
  let(:other_organization) { create(:organization) } unless method_defined?(:other_organization)

  it 'ignores hooks of other organizations' do
    create(:system_hook, organization: other_organization, **hook_attributes)

    expect(system_hooks_active?).to be(false)
  end

  it 'finds hooks of the organization', :aggregate_failures do
    create(:system_hook, organization: organization, **hook_attributes)
    active = nil

    expect { active = system_hooks_active? }.not_to query_system_hooks_without_organization_id
    expect(active).to be(true)
  end
end

# Define `listed_system_hook_ids` to run the code path and return the IDs of the hooks it lists.
RSpec.shared_examples 'system hook listing scoped to the organization' do
  let(:other_organization) { create(:organization) } unless method_defined?(:other_organization)
  let!(:other_organization_hook) { create(:system_hook, organization: other_organization) }
  let!(:organization_hook) { create(:system_hook, organization: organization) }

  it 'lists only the hooks of the organization', :aggregate_failures do
    ids = nil

    expect { ids = listed_system_hook_ids }.not_to query_system_hooks_without_organization_id

    expect(ids).to include(organization_hook.id)
    expect(ids).not_to include(other_organization_hook.id)
  end
end

# Define `request_system_hook(hook)` to make a request that looks up the given hook.
RSpec.shared_examples 'system hook lookup scoped to the organization' do |hook_attributes: {}|
  include StubRequests

  let(:other_organization) { create(:organization) } unless method_defined?(:other_organization)
  let!(:other_organization_hook) { create(:system_hook, organization: other_organization, **hook_attributes) }
  let!(:organization_hook) { create(:system_hook, organization: organization, **hook_attributes) }

  it 'finds a hook of the organization', :aggregate_failures do
    stub_full_request(organization_hook.interpolated_url, method: :post)

    expect { request_system_hook(organization_hook) }.not_to query_system_hooks_without_organization_id

    expect(response).to have_gitlab_http_status(:success).or have_gitlab_http_status(:redirect)
  end

  it 'returns 404 and does not act on a hook of another organization', :aggregate_failures do
    expect(WebHookService).not_to receive(:new)

    expect { request_system_hook(other_organization_hook) }
      .not_to change { SystemHook.find_by(id: other_organization_hook.id)&.attributes }

    expect(response).to have_gitlab_http_status(:not_found)
  end
end
