# frozen_string_literal: true

require 'rubocop_spec_helper'
require_relative '../../../../rubocop/cop/api/base'

RSpec.describe RuboCop::Cop::API::Base do
  let(:corrected) do
    <<~CORRECTED
      class SomeAPI < ::API::Base
      end
    CORRECTED
  end

  %w[Grape::API ::Grape::API Grape::API::Instance ::Grape::API::Instance].each do |offense|
    it "adds an offense when inheriting from #{offense}" do
      expect_offense(<<~CODE)
        class SomeAPI < #{offense}
                        #{'^' * offense.length} #{described_class::MSG}
        end
      CODE

      expect_correction(corrected)
    end
  end

  it 'does not add an offense when inheriting from BaseAPI' do
    expect_no_offenses(corrected)
  end
end
