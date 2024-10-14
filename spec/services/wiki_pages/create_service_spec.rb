# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiPages::CreateService, feature_category: :wiki do
  it_behaves_like 'WikiPages::CreateService#execute', :project
end
