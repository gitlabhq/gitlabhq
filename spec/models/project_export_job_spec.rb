# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectExportJob, type: :model do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:relation_exports) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:jid) }
    it { is_expected.to validate_presence_of(:status) }
  end
end
