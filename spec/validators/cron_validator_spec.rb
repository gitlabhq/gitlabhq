# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CronValidator do
  subject do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations
      attr_accessor :cron

      validates :cron, cron: true

      def cron_timezone
        'UTC'
      end
    end.new
  end

  it 'validates valid crontab' do
    subject.cron = '0 23 * * 5'

    expect(subject.valid?).to be_truthy
  end

  it 'validates invalid crontab' do
    subject.cron = 'not a cron'

    expect(subject.valid?).to be_falsy
  end

  context 'cron field is not allowlisted' do
    subject do
      Class.new do
        include ActiveModel::Model
        include ActiveModel::Validations
        attr_accessor :cron_partytime

        validates :cron_partytime, cron: true
      end.new
    end

    it 'raises an error' do
      subject.cron_partytime = '0 23 * * 5'

      expect { subject.valid? }.to raise_error(StandardError, "Non-allowlisted attribute")
    end
  end
end
