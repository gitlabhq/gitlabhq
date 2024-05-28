# frozen_string_literal: true

require 'spec_helper'

# These specs only make sense if ee/spec/spec_helper is loaded
# In FOSS_ONLY=1 mode, nothing should happen
RSpec.describe 'license metadata tags', feature_category: :plan_provisioning, if: Gitlab.ee? do
  it 'applies the without_license metadata tag by default' do |example|
    expect(example.metadata[:without_license]).to eq(true)
  end

  it 'does not apply the with_license metadata tag by default' do |example|
    expect(example.metadata[:with_license]).to be_nil
  end

  it 'does not have a current license' do
    expect(License.current).to be_nil
  end

  context 'with with_license tag', :with_license do
    it 'has a current license' do
      expect(License.current).to be_present
    end
  end

  context 'with without_license tag', :without_license do
    it 'does not have a current license' do
      expect(License.current).to be_nil
    end
  end
end
