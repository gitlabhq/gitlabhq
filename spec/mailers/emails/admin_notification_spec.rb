# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Emails::AdminNotification do
  include EmailSpec::Matchers
  include_context 'gitlab email notification'

  it 'adds email methods to Notify' do
    subject.instance_methods.each do |email_method|
      expect(Notify).to be_respond_to(email_method)
    end
  end
end
