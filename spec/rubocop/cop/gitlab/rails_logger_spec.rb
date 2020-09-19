# frozen_string_literal: true

require 'fast_spec_helper'
require 'rubocop'
require 'rubocop/rspec/support'
require_relative '../../../../rubocop/cop/gitlab/rails_logger'

RSpec.describe RuboCop::Cop::Gitlab::RailsLogger, type: :rubocop do
  include CopHelper

  subject(:cop) { described_class.new }

  described_class::LOG_METHODS.each do |method|
    it "flags the use of Rails.logger.#{method} with a constant receiver" do
      inspect_source("Rails.logger.#{method}('some error')")

      expect(cop.offenses.size).to eq(1)
    end
  end

  it 'does not flag the use of Rails.logger with a constant that is not Rails' do
    inspect_source("AppLogger.error('some error')")

    expect(cop.offenses.size).to eq(0)
  end

  it 'does not flag the use of logger with a send receiver' do
    inspect_source("file_logger.info('important info')")

    expect(cop.offenses.size).to eq(0)
  end

  it 'does not flag the use of Rails.logger.level' do
    inspect_source("Rails.logger.level")

    expect(cop.offenses.size).to eq(0)
  end
end
