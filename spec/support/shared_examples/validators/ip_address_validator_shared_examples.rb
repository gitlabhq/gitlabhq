# frozen_string_literal: true

RSpec.shared_examples 'validates IP address' do
  subject { object }

  it { is_expected.to allow_value('192.168.17.43').for(attribute.to_sym) }
  it { is_expected.to allow_value('2001:0db8:85a3:0000:0000:8a2e:0370:7334').for(attribute.to_sym) }

  it { is_expected.not_to allow_value('invalid IP').for(attribute.to_sym) }
end
