# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Devise initializer for GitLab', :delete, :reestablished_active_record_base, feature_category: :system_access do
  def load_initializers
    load Rails.root.join('config/initializers/8_devise.rb')
    load Rails.root.join('config/initializers/load_balancing.rb')
  end

  describe "unlock configuration" do
    before do
      allow(Gitlab::Application.instance.middleware).to receive(:use)
      allow(Gitlab::CurrentSettings).to receive(:max_login_attempts).and_return(35)
      allow(Gitlab::CurrentSettings).to receive(:failed_login_attempts_unlock_period_in_minutes).and_return(15)
      load_initializers
    end

    it "sets custom maximum attempts" do
      expect(Devise.maximum_attempts).to be_eql(35)
    end

    it "sets custom unlock_in" do
      expect(Devise.unlock_in).to be_eql(15.minutes)
    end
  end
end
