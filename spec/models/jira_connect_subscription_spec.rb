# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JiraConnectSubscription do
  describe 'associations' do
    it { is_expected.to belong_to(:installation).class_name('JiraConnectInstallation') }
    it { is_expected.to belong_to(:namespace).class_name('Namespace') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:installation) }
    it { is_expected.to validate_presence_of(:namespace) }
  end
end
