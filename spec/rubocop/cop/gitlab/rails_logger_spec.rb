# frozen_string_literal: true

require 'spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/rails_logger'

describe RuboCop::Cop::Gitlab::RailsLogger do
  include CopHelper

  subject(:cop) { described_class.new }

  it 'flags the use of Rails.logger.error with a constant receiver' do
    inspect_source("Rails.logger.error('some error')")

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of Rails.logger.info with a constant receiver' do
    inspect_source("Rails.logger.info('some info')")

    expect(cop.offenses.size).to eq(1)
  end

  it 'flags the use of Rails.logger.warn with a constant receiver' do
    inspect_source("Rails.logger.warn('some warning')")

    expect(cop.offenses.size).to eq(1)
  end

  it 'does not flag the use of Rails.logger with a constant that is not Rails' do
    inspect_source("AppLogger.error('some error')")

    expect(cop.offenses.size).to eq(0)
  end

  it 'does not flag the use of logger with a send receiver' do
    inspect_source("file_logger.info('important info')")

    expect(cop.offenses.size).to eq(0)
  end
end
