# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Graphql::CallsGitaly::Instrumentation do
  subject { described_class.new }

  describe '#calls_gitaly_check' do
    let(:gitaly_field) { Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true) }
    let(:no_gitaly_field) { Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: false) }

    context 'if there are no Gitaly calls' do
      it 'does not raise an error if calls_gitaly is false' do
        expect { subject.send(:calls_gitaly_check, no_gitaly_field, 0) }.not_to raise_error
      end
    end

    context 'if there is at least 1 Gitaly call' do
      it 'raises an error if calls_gitaly: is false or not defined' do
        expect { subject.send(:calls_gitaly_check, no_gitaly_field, 1) }.to raise_error(/specify a constant complexity or add `calls_gitaly: true`/)
      end
    end
  end
end
