# == Schema Information
#
# Table name: emails
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  email      :string(255)      not null
#  created_at :datetime
#  updated_at :datetime
#

require 'spec_helper'

describe Email, models: true do

  describe 'validations' do
    it_behaves_like 'an object with email-formated attributes', :email do
      subject { build(:email) }
    end
  end

end
