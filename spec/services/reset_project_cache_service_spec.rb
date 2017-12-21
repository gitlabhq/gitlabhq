require 'spec_helper'

describe ResetProjectCacheService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user).execute }

  it "resets project cache" do
    fail
  end
end
