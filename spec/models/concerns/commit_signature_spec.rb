# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CommitSignature, feature_category: :source_code_management do
  subject(:implementation) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'ssh_signatures'
    end.include(described_class).new
  end

  describe '#signed_by_user' do
    context 'when class does not define the signed_by_user method' do
      it 'raises a NoMethodError with custom message' do
        expect do
          implementation.signed_by_user
        end.to raise_error(NoMethodError, 'must implement `signed_by_user` method')
      end
    end
  end

  describe 'enums' do
    it 'defines enums for verification statuses' do
      is_expected.to define_enum_for(:verification_status).with_values(
        ::Enums::CommitSignature.verification_statuses
      )
    end
  end
end
