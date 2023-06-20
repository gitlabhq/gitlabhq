# frozen_string_literal: true

require 'spec_helper'

class LoggerA < Gitlab::Logger
  def self.file_name_noext
    'loggerA'
  end
end

class LoggerB < Gitlab::JsonLogger
  def self.file_name_noext
    'loggerB'
  end
end

class TestLogger < Gitlab::MultiDestinationLogger
  LOGGERS = [LoggerA, LoggerB].freeze

  def self.loggers
    LOGGERS
  end
end

class EmptyLogger < Gitlab::MultiDestinationLogger
  def self.loggers
    []
  end
end

RSpec.describe Gitlab::MultiDestinationLogger do
  after(:all) do
    TestLogger.loggers.each do |logger|
      log_file_path = "#{Rails.root}/log/#{logger.file_name}"
      File.delete(log_file_path)
    end
  end

  context 'with no primary logger set' do
    subject { EmptyLogger }

    it 'primary_logger raises an error' do
      expect { subject.primary_logger }.to raise_error(NotImplementedError)
    end
  end

  context 'with 2 loggers set' do
    subject { TestLogger }

    it 'logs info to 2 loggers' do
      expect(subject.loggers).to all(receive(:build).and_call_original)

      subject.info('Hello World')
    end
  end
end
