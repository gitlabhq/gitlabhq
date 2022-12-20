# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Iso8601DateValidator do
  subject do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'deploy_tokens'

      attribute :expires_at

      validates :expires_at, iso8601_date: true

      def self.name
        "DeployToken"
      end
    end.new
  end

  it 'passes a valid date' do
    subject.expires_at = DateTime.now

    expect(subject.valid?).to be_truthy
  end

  it 'errors on an invalid date' do
    subject.expires_at = '2-12-2022'

    expect(subject.valid?).to be_falsy
    expect(subject.errors.full_messages).to include('Expires at must be in ISO 8601 format')
  end
end
