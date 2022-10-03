# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Capybara::Node::Base::SlowFinder do # rubocop:disable RSpec/FilePath
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
    let(:slow_finder) do
      Class.new do
        def synchronize(seconds = nil, errors: nil)
          sleep 0.1

          raise Capybara::ElementNotFound
        end

        prepend Capybara::Node::Base::SlowFinder
      end.new
    end

    it 'raises a timeout error' do
      expect { slow_finder.synchronize(0.01) }.to raise_error(
        Capybara::ElementNotFound,
        /Timeout reached while running a waiting Capybara finder./
      )
    end
  end
end
