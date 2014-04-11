# == Schema Information
#
# Table name: project_templates
#
#  id          :integer          not null, primary key
#  name        :string(100)
#  save_name   :string(200)      not null
#  description :text
#  upload      :string(400)
#  state       :integer          default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

require 'spec_helper'

describe ProjectTemplate do

  describe "create" do
    let(:project_template) { build(:project_template) }

    it { should validate_presence_of(:name) }
    it { should ensure_length_of(:name).is_within(0..100) }

    it { should ensure_length_of(:description).is_within(0..750) }

    it { project_template.state.should equal(0) }
  end

end
