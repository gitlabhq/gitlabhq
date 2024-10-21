# frozen_string_literal: true

require 'fast_spec_helper'
require 'capybara'
require 'support/capybara_slow_finder'

RSpec.describe Capybara::Node::Base::SlowFinder do # rubocop:disable RSpec/SpecFilePathFormat
  context 'without timeout' do
    context 'when element is found' do
      let(:slow_finder) do
        Class.new do
          def synchronize(seconds = nil, errors: nil)
            true
          end

          prepend Capybara::Node::Base::SlowFinder
        end.new
      end

      it 'does not raise error' do
        expect { slow_finder.synchronize }.not_to raise_error
      end
    end

    context 'when element is not found' do
      let(:slow_finder) do
        Class.new do
          def synchronize(seconds = nil, errors: nil)
            raise Capybara::ElementNotFound
          end

          prepend Capybara::Node::Base::SlowFinder
        end.new
      end

      it 'raises Capybara::ElementNotFound error' do
        expect { slow_finder.synchronize }.to raise_error(Capybara::ElementNotFound)
      end
    end
  end

  context 'with timeout' do
    let(:timeout) { 0.01 }

    let(:slow_finder) do
      Class.new do
        def synchronize(seconds = nil, errors: nil)
          sleep 0.02

          raise Capybara::ElementNotFound
        end

        prepend Capybara::Node::Base::SlowFinder
      end.new
    end

    context 'with default timeout' do
      it 'raises a timeout error' do
        expect(Capybara).to receive(:default_max_wait_time).and_return(timeout)

        expect { slow_finder.synchronize }.to raise_error_element_not_found
      end
    end

    context 'when passed as paramater' do
      it 'raises a timeout error' do
        expect { slow_finder.synchronize(timeout) }.to raise_error_element_not_found
      end
    end

    def raise_error_element_not_found
      raise_error(
        Capybara::ElementNotFound,
        /\n\nTimeout \(#{timeout}s\) reached while running a waiting Capybara finder./
      )
    end
  end
end
