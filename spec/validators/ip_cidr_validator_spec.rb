# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IpCidrValidator, feature_category: :shared do
  let(:model) do
    Class.new do
      include ActiveModel::Model
      include ActiveModel::Validations

      attr_accessor :cidr
      alias_method :cidr_before_type_cast, :cidr

      validates :cidr, ip_cidr: true
    end.new
  end

  using RSpec::Parameterized::TableSyntax

  where(:cidr, :validity, :errors) do
    # rubocop:disable Layout/LineLength -- The RSpec table syntax often requires long lines for errors'
    'invalid-CIDR'                  | false | { cidr: ["IP 'invalid-CIDR' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    '172.0.0.1|256'                 | false | { cidr: ["IP '172.0.0.1|256' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    '172.0.0.1'                     | false | { cidr: ["IP '172.0.0.1' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    '172.0.0.1/2/12'                | false | { cidr: ["IP '172.0.0.1/2/12' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    '172.0.0.1/256'                 | false | { cidr: ["IP '172.0.0.1/256' is not a valid CIDR: Invalid netmask 256"] }
    '2001:db8::8:800:200c:417a/129' | false | { cidr: ["IP '2001:db8::8:800:200c:417a/129' is not a valid CIDR: Prefix must be in range 0..128, got: 129"] }
    '2001:db8::8:800:200c:417a'     | false | { cidr: ["IP '2001:db8::8:800:200c:417a' is not a valid CIDR: IP should be followed by a slash followed by an integer subnet mask (for example: '192.168.1.0/24')"] }
    '2001:db8::8:800:200c:417a/128' | true  | {}
    '172.0.0.1/32'                  | true  | {}
    ''                              | true  | {}
    nil                             | true  | {}
    # rubocop:enable Layout/LineLength
  end

  with_them do
    before do
      model.cidr = cidr
      model.validate
    end

    it { expect(model.valid?).to eq(validity) }
    it { expect(model.errors.messages).to eq(errors) }
  end
end
