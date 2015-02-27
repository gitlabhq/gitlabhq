# == Schema Information
#
# Table name: application_settings
#
#  id                         :integer          not null, primary key
#  default_projects_limit     :integer
#  default_branch_protection  :integer
#  signup_enabled             :boolean
#  signin_enabled             :boolean
#  gravatar_enabled           :boolean
#  sign_in_text               :text
#  created_at                 :datetime
#  updated_at                 :datetime
#  home_page_url              :string(255)
#

require 'spec_helper'

describe ApplicationSetting, models: true do
  it { expect(ApplicationSetting.create_from_defaults).to be_valid }
end
