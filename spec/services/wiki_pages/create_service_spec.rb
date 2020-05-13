# frozen_string_literal: true

require 'spec_helper'

describe WikiPages::CreateService do
  it_behaves_like 'WikiPages::CreateService#execute', :project
end
