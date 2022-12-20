# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Harbor::TagsController, feature_category: :source_code_management do
  it_behaves_like 'a harbor tags controller', anonymous_status_code: '302' do
    let_it_be(:container) { create(:project) }
    let_it_be(:harbor_integration) { create(:harbor_integration, project: container) }
  end
end
