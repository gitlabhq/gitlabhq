# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::Harbor::ArtifactsController, feature_category: :job_artifacts do
  it_behaves_like 'a harbor artifacts controller', anonymous_status_code: '404' do
    let_it_be(:container) { create(:group) }
    let_it_be(:harbor_integration) { create(:harbor_integration, group: container, project: nil) }
  end
end
