# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::Projects::Menus::ZentaoMenu, feature_category: :navigation do
  it_behaves_like 'ZenTao menu with CE version'
end
