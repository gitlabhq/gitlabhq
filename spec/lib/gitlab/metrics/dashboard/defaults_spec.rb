# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Metrics::Dashboard::Defaults do
  it { is_expected.to be_const_defined(:DEFAULT_PANEL_TYPE) }
end
