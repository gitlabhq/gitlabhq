# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../../rubocop/cop/performance/active_record_subtransaction_methods'

RSpec.describe RuboCop::Cop::Performance::ActiveRecordSubtransactionMethods do
  subject(:cop) { described_class.new }

  let(:message) { described_class::MSG }

  shared_examples 'a method that uses a subtransaction' do |method_name|
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        Project.#{method_name}
                #{'^' * method_name.length} #{message}
      RUBY
    end
  end

  context 'when the method uses a subtransaction' do
    described_class::DISALLOWED_METHODS.each do |method|
      it_behaves_like 'a method that uses a subtransaction', method
    end
  end
end
