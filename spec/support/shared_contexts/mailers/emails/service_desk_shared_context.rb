# frozen_string_literal: true

RSpec.shared_context 'with service desk mailer' do
  before do
    stub_const('ServiceEmailClass', Class.new(ApplicationMailer))

    ServiceEmailClass.class_eval do
      mattr_accessor :override_layout_lookup_table, default: {}

      include GitlabRoutingHelper
      include EmailsHelper
      include Emails::ServiceDesk

      helper GitlabRoutingHelper
      helper EmailsHelper

      layout :determine_layout

      def determine_layout
        override_layout_lookup_table[action_name&.to_sym]
      end

      # this method is implemented in Notify class, we don't need to test it
      def reply_key
        'b7721fc7e8419911a8bea145236a0519'
      end

      # this method is implemented in Notify class, we don't need to test it
      def sender(author_id, params = {})
        author_id
      end

      # this method is implemented in Notify class
      #
      # We do not need to test the Notify method, it is already tested in notify_spec
      def mail_new_thread(issue, options)
        # we need to rewrite this in order to look up templates in the correct directory
        self.class.mailer_name = 'notify'

        # this is needed for default layout
        @unsubscribe_url = 'http://unsubscribe.example.com'

        mail(options)
      end
      alias_method :mail_answer_thread, :mail_new_thread
    end
  end
end
