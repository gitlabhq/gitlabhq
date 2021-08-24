# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Topic do
  let_it_be(:topic, reload: true) { create(:topic) }

  subject { topic }

  it { expect(subject).to be_valid }

  describe 'associations' do
    it { is_expected.to have_many(:project_topics) }
    it { is_expected.to have_many(:projects) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end
end
