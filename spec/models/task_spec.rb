# == Schema Information
#
# Table name: tasks
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  project_id  :integer          not null
#  target_id   :integer          not null
#  target_type :string           not null
#  author_id   :integer
#  action      :integer
#  state       :string           not null
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe Task, models: true do
  describe 'relationships' do
    it { is_expected.to belong_to(:author).class_name("User") }
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:target).touch(true) }
    it { is_expected.to belong_to(:user) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_presence_of(:target) }
    it { is_expected.to validate_presence_of(:user) }
  end
end
