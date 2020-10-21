# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IpAddressValidator do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :ip_address
      alias_method :ip_address_before_type_cast, :ip_address

      validates :ip_address, ip_address: true
    end.new
  end

  using RSpec::Parameterized::TableSyntax

  where(:ip_address, :validity, :errors) do
    'invalid IP'                     | false | { ip_address: ['must be a valid IPv4 or IPv6 address'] }
    '192.168.17.43'                  | true  | {}
    '2001:0db8:85a3::8a2e:0370:7334' | true  | {}
    nil                              | true  | {}
    ''                               | true  | {}
  end

  with_them do
    before do
      model.ip_address = ip_address
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
