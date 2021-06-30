# frozen_string_literal: true

# Expects usage of 'incident settings enabled' context.
#
# This shared_example includes the following option:
# - with_issue: includes a test for when the defined `alert` has an associated issue
#
# This shared_example requires the following variables:
# - `alert`, required if :with_issue is true
RSpec.shared_examples 'processes incident issues if enabled' do |with_issue: false|
  include_examples 'processes incident issues', with_issue

  context 'with incident setting disabled' do
    let(:create_issue) { false }

    it_behaves_like 'does not process incident issues'
  end
end

RSpec.shared_examples 'processes incident issues' do |with_issue: false|
  before do
    allow_next_instance_of(AlertManagement::Alert) do |alert|
      allow(alert).to receive(:execute_integrations)
    end
  end

  specify do
    expect(IncidentManagement::ProcessAlertWorkerV2)
      .to receive(:perform_async)
      .with(kind_of(Integer))

    Sidekiq::Testing.inline! do
      expect(subject).to be_success
    end
  end

  context 'with issue', if: with_issue do
    before do
      alert.update!(issue: create(:issue, project: project))
    end

    it_behaves_like 'does not process incident issues'
  end
end

RSpec.shared_examples 'does not process incident issues' do
  specify do
    expect(IncidentManagement::ProcessAlertWorkerV2).not_to receive(:perform_async)

    subject
  end
end
