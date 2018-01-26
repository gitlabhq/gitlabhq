require 'rails_helper'

describe Callout do
  let(:callout) { create(:callout) }

  describe 'relationships' do
    it { is_expected.to belong_to(:user) }
  end
end
