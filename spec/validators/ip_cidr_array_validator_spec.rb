# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IpCidrArrayValidator, feature_category: :shared do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :cidr_array
      alias_method :cidr_array_before_type_cast, :cidr_array

      validates :cidr_array, ip_cidr_array: true
    end.new
  end

  using RSpec::Parameterized::TableSyntax

  where(:cidr_array, :validity, :errors) do
    # rubocop:disable Layout/LineLength -- The RSpec table syntax often requires long lines for errors
    nil                                               | false | { cidr_array: ["must be an array of CIDR values"] }
    ''                                                | false | { cidr_array: ["must be an array of CIDR values"] }
    ['172.0.0.1/256']                                 | false | { cidr_array: ["IP '172.0.0.1/256' is not a valid CIDR: Invalid netmask 256"] }
    %w[172.0.0.1/24 invalid-CIDR]                     | false | { cidr_array: ["IP 'invalid-CIDR' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    %w[172.0.0.1/256 invalid-CIDR]                    | false | { cidr_array: ["IP '172.0.0.1/256' is not a valid CIDR: Invalid netmask 256", "IP 'invalid-CIDR' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    ['172.0.0.1/24', nil]                             | true  | {}
    %w[172.0.0.1/24 2001:db8::8:800:200c:417a/128]    | true  | {}
    []                                                | true  | {}
    [nil]                                             | true  | {}
    ['']                                              | true  | {}
    # rubocop:enable Layout/LineLength
  end

  with_them do
    before do
      model.cidr_array = cidr_array
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
