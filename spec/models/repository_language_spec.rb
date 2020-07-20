# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RepositoryLanguage do
  let(:repository_language) { build(:repository_language) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:programming_language) }
  end

  describe 'validations' do
    it { is_expected.to allow_value(0).for(:share) }
    it { is_expected.to allow_value(100.0).for(:share) }
    it { is_expected.not_to allow_value(100.1).for(:share) }
  end
end
