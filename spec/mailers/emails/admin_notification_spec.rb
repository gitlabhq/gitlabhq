# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AdminNotification do
  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end
end
