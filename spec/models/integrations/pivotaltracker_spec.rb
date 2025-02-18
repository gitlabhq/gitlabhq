# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Pivotaltracker, feature_category: :integrations do
  it_behaves_like Integrations::Base::Pivotaltracker
end
