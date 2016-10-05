require 'spec_helper'

describe GroupHook do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end
end
