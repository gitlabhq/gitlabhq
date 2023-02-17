# frozen_string_literal: true

RSpec.shared_examples 'issue_edit snowplow tracking' do
  let(:category) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_CATEGORY }
  let(:action) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_ACTION }
  let(:label) { Gitlab::UsageDataCounters::IssueActivityUniqueCounter::ISSUE_LABEL }
  let(:namespace) { project.namespace }

  it_behaves_like 'Snowplow event tracking with RedisHLL context'
end
