# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignature do
  describe '#signed_by_user' do
    context 'when class does not define the signed_by_user method' do
      subject(:implementation) do
        Class.new(ActiveRecord::Base) do
          self.table_name = 'ssh_signatures'
        end.include(described_class).new
      end

      it 'raises a NoMethodError with custom message' do
        expect do
          implementation.signed_by_user
        end.to raise_error(NoMethodError, 'must implement `signed_by_user` method')
      end
    end
  end
end
