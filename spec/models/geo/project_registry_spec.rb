require 'spec_helper'

describe Geo::ProjectRegistry, models: true do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:project_id) }
  end
end
