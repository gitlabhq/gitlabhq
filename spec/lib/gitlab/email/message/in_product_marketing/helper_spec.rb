# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Message::InProductMarketing::Helper do
  describe 'unsubscribe_message' do
    include Gitlab::Routing

    let(:dummy_class_with_helper) do
      Class.new do
        include Gitlab::Email::Message::InProductMarketing::Helper
        include Gitlab::Routing

        def initialize(format = :html)
          @format = format
        end

        def default_url_options
          {}
        end

        attr_accessor :format
      end
    end

    let(:format) { :html }

    subject(:class_with_helper) { dummy_class_with_helper.new(format) }

    context 'for SaaS', :saas do
      context 'format is HTML' do
        it 'returns the correct HTML' do
          message = "If you no longer wish to receive marketing emails from us, " \
            "you may <a href=\"%tag_unsubscribe_url%\">unsubscribe</a> at any time."
          expect(class_with_helper.unsubscribe_message).to match message
        end
      end

      context 'format is text' do
        let(:format) { :text }

        it 'returns the correct string' do
          message = "If you no longer wish to receive marketing emails from us, " \
            "you may unsubscribe (%tag_unsubscribe_url%) at any time."
          expect(class_with_helper.unsubscribe_message.squish).to match message
        end
      end
    end

    context 'self-managed' do
      context 'format is HTML' do
        it 'returns the correct HTML' do
          preferences_link = "http://example.com/preferences"
          message = "To opt out of these onboarding emails, " \
            "<a href=\"#{profile_notifications_url}\">unsubscribe</a>. " \
            "If you don't want to receive marketing emails directly from GitLab, #{preferences_link}."
          expect(class_with_helper.unsubscribe_message(preferences_link))
            .to match message
        end
      end

      context 'format is text' do
        let(:format) { :text }

        it 'returns the correct string' do
          preferences_link = "http://example.com/preferences"
          message = "To opt out of these onboarding emails, " \
            "unsubscribe (#{profile_notifications_url}). " \
            "If you don't want to receive marketing emails directly from GitLab, #{preferences_link}."
          expect(class_with_helper.unsubscribe_message(preferences_link).squish).to match message
        end
      end
    end
  end
end
