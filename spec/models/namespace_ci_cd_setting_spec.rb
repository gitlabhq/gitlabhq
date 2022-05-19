# frozen_string_literal: true

require 'spec_helper'

RSpec.describe NamespaceCiCdSetting do
  describe "associations" do
    it { is_expected.to belong_to(:namespace).inverse_of(:ci_cd_settings) }
  end
end
