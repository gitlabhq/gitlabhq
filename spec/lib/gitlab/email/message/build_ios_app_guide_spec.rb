# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::BuildIosAppGuide, :saas do
  subject(:message) { described_class.new }

  it 'contains the correct message', :aggregate_failures do
    expect(message.subject_line).to eq 'Get set up to build for iOS'
    expect(message.title).to eq "Building for iOS? We've got you covered."
    expect(message.body_line1).to eq "Want to get your iOS app up and running, including " \
      "publishing all the way to TestFlight? Follow our guide to set up GitLab and fastlane to publish iOS apps to " \
      "the App Store."
    expect(message.cta_text).to eq 'Learn how to build for iOS'
    expect(message.cta2_text).to eq 'Watch iOS building in action.'
    expect(message.logo_path).to eq 'mailers/in_product_marketing/create-0.png'
    expect(message.unsubscribe).to include('%tag_unsubscribe_url%')
  end
end
