# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Repositories::HousekeepingService, feature_category: :source_code_management do
  it_behaves_like 'housekeeps repository' do
    let_it_be(:resource) { create(:project, :repository) }
  end

  it_behaves_like 'housekeeps repository' do
    let_it_be(:project) { create(:project, :wiki_repo) }
    let_it_be(:resource) { project.wiki }
  end
end
