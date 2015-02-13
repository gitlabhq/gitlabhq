# == Schema Information
#
# Table name: snippets
#
#  id               :integer          not null, primary key
#  title            :string(255)
#  content          :text
#  author_id        :integer          not null
#  project_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#  file_name        :string(255)
#  expires_at       :datetime
#  type             :string(255)
#  visibility_level :integer          default(0), not null
#

require 'spec_helper'

describe Snippet do
  describe "Associations" do
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to have_many(:notes).dependent(:destroy) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:author) }

    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to ensure_length_of(:title).is_within(0..255) }

    it { is_expected.to validate_presence_of(:file_name) }
    it { is_expected.to ensure_length_of(:title).is_within(0..255) }

    it { is_expected.to validate_presence_of(:content) }
  end
end
