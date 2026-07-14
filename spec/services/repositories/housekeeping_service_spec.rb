# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::HousekeepingService, feature_category: :source_code_management do
  it_behaves_like 'housekeeps repository' do
    # `freeze: false` is required in this spec: one or more `let_it_be` subjects
    # cannot be frozen by default (deep_freeze traversal failure, a non-AR
    # subject, or an in-memory mutation that survives reload/refind). Do not
    # drop these opt-outs or convert them to `let_it_be_with_reload`/`refind`
    # (see gitlab-org/gitlab#602925).
    let_it_be(:resource, freeze: false) { create(:project, :repository) }
  end

  it_behaves_like 'housekeeps repository' do
    let_it_be(:project) { create(:project, :wiki_repo) }
    let_it_be(:resource, freeze: false) { project.wiki }
  end
end
