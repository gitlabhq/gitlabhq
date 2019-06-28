# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Graphql::CallsGitaly::Instrumentation do
  subject { described_class.new }

  context 'when considering complexity' do
    describe '#calls_gitaly_check' do
      let(:gitaly_field) { Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: true) }
      let(:no_gitaly_field) { Types::BaseField.new(name: 'test', type: GraphQL::STRING_TYPE, null: true, calls_gitaly: false) }

      context 'if there are no Gitaly calls' do
        it 'does not raise an error if calls_gitaly is false' do
          expect { subject.send(:calls_gitaly_check, no_gitaly_field, 0) }.not_to raise_error
        end
      end

      context 'if there is at least 1 Gitaly call' do
        it 'does not raise an error if calls_gitaly is true' do
          expect { subject.send(:calls_gitaly_check, gitaly_field, 1) }.not_to raise_error
        end

        it 'raises an error if calls_gitaly: is false or not defined' do
          expect { subject.send(:calls_gitaly_check, no_gitaly_field, 1) }.to raise_error(/please add `calls_gitaly: true`/)
        end
      end
    end
  end
end
