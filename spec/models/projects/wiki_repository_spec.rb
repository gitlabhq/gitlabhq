# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WikiRepository do
  subject { described_class.new(project: build(:project)) }

  describe 'associations' do
    it { is_expected.to belong_to(:project).inverse_of(:wiki_repository) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_uniqueness_of(:project) }
  end
end
