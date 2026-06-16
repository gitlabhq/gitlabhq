# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Email::Handler::BaseHandler, feature_category: :team_planning do
  let(:handler) { described_class.new(Mail::Message.new, 'mail_key') }

  describe '#additional_log_data' do
    it 'returns an empty hash by default' do
      expect(handler.send(:additional_log_data)).to eq({})
    end
  end
end
