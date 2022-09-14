# frozen_string_literal: true

require 'rubocop_spec_helper'
require 'rspec-parameterized'

require_relative '../../../../rubocop/cop/performance/active_record_subtransaction_methods'

RSpec.describe RuboCop::Cop::Performance::ActiveRecordSubtransactionMethods do
  let(:message) { described_class::MSG }

  shared_examples 'a method that uses a subtransaction' do |method_name|
    it 'registers an offense' do
      expect_offense(<<~RUBY, method_name: method_name, message: message)
        Project.%{method_name}
                ^{method_name} %{message}
      RUBY
    end
  end

  context 'when the method uses a subtransaction' do
    where(:method) { described_class::DISALLOWED_METHODS.to_a }

    with_them do
      include_examples 'a method that uses a subtransaction', params[:method]
    end
  end
end
