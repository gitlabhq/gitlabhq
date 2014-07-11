# == Schema Information
#
# Table name: snippets
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  content    :text
#  author_id  :integer          not null
#  project_id :integer
#  created_at :datetime
#  updated_at :datetime
#  file_name  :string(255)
#  expires_at :datetime
#  private    :boolean          default(TRUE), not null
#  type       :string(255)
#

require 'spec_helper'

describe Snippet do
  describe "Associations" do
    it { should belong_to(:author).class_name('User') }
    it { should have_many(:notes).dependent(:destroy) }
  end

  describe "Mass assignment" do
  end

  describe "Validation" do
    it { should validate_presence_of(:author) }

    it { should validate_presence_of(:title) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:file_name) }
    it { should ensure_length_of(:title).is_within(0..255) }

    it { should validate_presence_of(:content) }
  end
end
