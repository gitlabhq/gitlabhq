# frozen_string_literal: true

require 'rubocop_spec_helper'

require_relative '../../../../rubocop/cop/usage_data/instrumentation_superclass'

RSpec.describe RuboCop::Cop::UsageData::InstrumentationSuperclass do
  let(:allowed_classes) { %i[GenericMetric DatabaseMetric RedisHllMetric] }
  let(:msg) { "Instrumentation classes should subclass one of the following: #{allowed_classes.join(', ')}." }

  let(:config) do
    RuboCop::Config.new('UsageData/InstrumentationSuperclass' => {
                          'AllowedClasses' => allowed_classes
                        })
  end

  context 'when in an instrumentation file' do
    before do
      allow(cop).to receive(:in_instrumentation_file?).and_return(true)
    end

    context 'with class definition' do
      context 'when inheriting from allowed superclass' do
        it 'does not register an offense' do
          expect_no_offenses('class NewMetric < GenericMetric; end')
        end
      end

      context 'when inheriting from some other superclass' do
        it 'registers an offense' do
          expect_offense(<<~CODE)
            class NewMetric < BaseMetric; end
                              ^^^^^^^^^^ #{msg}
          CODE
        end
      end

      context 'when not inheriting' do
        it 'does not register an offense' do
          expect_no_offenses('class NewMetric; end')
        end
      end
    end

    context 'with dynamic class definition' do
      context 'when inheriting from allowed superclass' do
        it 'does not register an offense' do
          expect_no_offenses('NewMetric = Class.new(GenericMetric)')
        end
      end

      context 'when inheriting from some other superclass' do
        it 'registers an offense' do
          expect_offense(<<~CODE)
            NewMetric = Class.new(BaseMetric)
                                  ^^^^^^^^^^ #{msg}
          CODE
        end
      end

      context 'when not inheriting' do
        it 'does not register an offense' do
          expect_no_offenses('NewMetric = Class.new')
        end
      end
    end
  end

  context 'when outside of an instrumentation file' do
    it "does not register an offense" do
      expect_no_offenses(<<-RUBY)
        class NewMetric < BaseMetric; end
      RUBY
    end
  end
end
