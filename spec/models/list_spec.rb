# frozen_string_literal: true

require 'spec_helper'

RSpec.describe List do
  it_behaves_like 'having unique enum values'
  it_behaves_like 'boards listable model', :list
  it_behaves_like 'list_preferences_for user', :list, :list_id

  describe 'relationships' do
    it { is_expected.to belong_to(:board) }
    it { is_expected.to belong_to(:label) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:board) }
    it { is_expected.to validate_presence_of(:label) }
    it { is_expected.to validate_presence_of(:list_type) }
  end
end
