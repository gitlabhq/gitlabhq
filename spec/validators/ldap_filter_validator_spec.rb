require 'spec_helper'

describe LdapFilterValidator do
  let(:validator) { described_class.new(attributes: [:filter]) }

  describe '#validates_each' do
    it 'adds a message when the filter is not valid' do
      link = build(:ldap_group_link, cn: nil)

      validator.validate_each(link, :filter, 'wrong filter')

      expect(link.errors[:filter]).to match_array(['must be a valid filter'])
    end

    it 'has no errors when is valid' do
      link = build(:ldap_group_link, cn: nil)

      validator.validate_each(link, :filter, '(cn=Babs Jensen)')

      expect(link.errors[:filter]).to eq([])
    end
  end
end
