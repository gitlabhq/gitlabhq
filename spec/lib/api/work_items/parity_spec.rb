# frozen_string_literal: true

require 'spec_helper'

# We expect more fields in EE, so we have a shared spec between CE and EE with different
# expectations about the fields. Since the CE test also runs in EE, we need to skip it.
RSpec.describe 'Work item API parity', feature_category: :team_planning, unless: Gitlab.ee? do
  it_behaves_like 'work item API parity'
end
