# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::UpdateService, feature_category: :wiki do
  it_behaves_like 'WikiPages::UpdateService#execute', :project
end
