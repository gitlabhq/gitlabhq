# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Packages::Composer::Metadatum, type: :model do
  describe 'relationships' do
    it { is_expected.to belong_to(:package) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:package) }
    it { is_expected.to validate_presence_of(:target_sha) }
    it { is_expected.to validate_presence_of(:composer_json) }
  end
end
