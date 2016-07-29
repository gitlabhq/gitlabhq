# == Schema Information
#
# Table name: web_hooks
#
#  id                    :integer          not null, primary key
#  url                   :string(255)
#  project_id            :integer
#  created_at            :datetime
#  updated_at            :datetime
#  type                  :string(255)      default("ProjectHook")
#  service_id            :integer
#  push_events           :boolean          default(TRUE), not null
#  issues_events         :boolean          default(FALSE), not null
#  merge_requests_events :boolean          default(FALSE), not null
#  tag_push_events       :boolean          default(FALSE)
#

require 'spec_helper'

describe GroupHook do
  describe "Associations" do
    it { is_expected.to belong_to :group }
  end
end
