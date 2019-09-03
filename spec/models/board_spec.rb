# frozen_string_literal: true

require 'spec_helper'

describe Board do
  describe 'relationships' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:lists).order(list_type: :asc, position: :asc).dependent(:delete_all) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
  end
end
