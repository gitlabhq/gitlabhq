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
#  type             :string(255)
#  visibility_level :integer          default(0), not null
#

require 'spec_helper'

describe ProjectSnippet, models: true do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project) }
  end
end
