# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../rubocop/cop/include_sidekiq_worker'

RSpec.describe RuboCop::Cop::IncludeSidekiqWorker do
  context 'when `Sidekiq::Worker` is included' do
    it 'registers an offense and corrects', :aggregate_failures do
      expect_offense(<<~RUBY)
        include Sidekiq::Worker
                ^^^^^^^^^^^^^^^ Include `ApplicationWorker`, not `Sidekiq::Worker`.
      RUBY

      expect_correction(<<~RUBY)
        include ApplicationWorker
      RUBY
    end
  end
end
