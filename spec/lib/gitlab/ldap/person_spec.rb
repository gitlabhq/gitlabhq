require 'spec_helper'

describe Gitlab::LDAP::Person do
  include LdapHelpers

  let(:entry) { ldap_user_entry('john.doe') }

  before do
    stub_ldap_config(
      options: {
        'attributes' => {
          'name' => 'cn',
          'email' => %w(mail email userPrincipalName)
        }
      }
    )
  end

  describe '.normalize_dn' do
    context 'when there is extraneous (but valid) whitespace' do
      it 'removes the extraneous whitespace' do
        given    = 'uid     =John Smith ,  ou = People, dc=  example,dc =com'
        expected = 'uid=John Smith,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end

      context 'for a DN with a single RDN' do
        it 'removes the extraneous whitespace' do
          given    = 'uid  =  John Smith'
          expected = 'uid=John Smith'
          expect(described_class.normalize_dn(given)).to eq(expected)
        end
      end

      context 'when there are escaped characters' do
        it 'removes extraneous whitespace without changing the escaped characters' do
          given    = 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com'
          expected = 'uid=Sebasti\\c3\\a1n\\ C.\\20Smith\\ ,ou=People (aka. \\22humans\\"),dc=example,dc=com'
          expect(described_class.normalize_dn(given)).to eq(expected)
        end
      end

      context 'with a multivalued RDN' do
        it 'removes extraneous whitespace without modifying the multivalued RDN' do
          given    = 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com'
          expected = 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
          expect(described_class.normalize_dn(given)).to eq(expected)
        end

        context 'with a telephoneNumber with a space after the plus sign' do
          # I am not sure whether a space after the telephoneNumber plus sign is valid,
          # and I am not sure if this is "proper" behavior under these conditions, and
          # I am not sure if it matters to us or anyone else, so rather than dig
          # through RFCs, I am only documenting the behavior here.
          it 'removes the space after the plus sign in the telephoneNumber' do
            given    = 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com'
            expected = 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
            expect(described_class.normalize_dn(given)).to eq(expected)
          end
        end
      end
    end

    context 'for a null DN (empty string)' do
      it 'returns empty string and does not error' do
        given    = ''
        expected = ''
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an escaped leading space in an attribute value' do
      it 'does not remove the escaped leading space (and does not error like Net::LDAP::DN.new does)' do
        given    = 'uid=\\ John Smith,ou=People,dc=example,dc=com'
        expected = 'uid=\\ John Smith,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an escaped trailing space in an attribute value' do
      it 'does not remove the escaped trailing space' do
        given    = 'uid=John Smith\\ ,ou=People,dc=example,dc=com'
        expected = 'uid=John Smith\\ ,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an escaped leading newline in an attribute value' do
      it 'does not remove the escaped leading newline' do
        given    = 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'
        expected = 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an escaped trailing newline in an attribute value' do
      it 'does not remove the escaped trailing newline' do
        given    = 'uid=John Smith\\\n,ou=People,dc=example,dc=com'
        expected = 'uid=John Smith\\\n,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an unescaped leading newline in an attribute value' do
      it 'does not remove the unescaped leading newline' do
        given    = 'uid=\nJohn Smith,ou=People,dc=example,dc=com'
        expected = 'uid=\nJohn Smith,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'when there is an unescaped trailing newline in an attribute value' do
      it 'does not remove the unescaped trailing newline' do
        given    = 'uid=John Smith\n ,ou=People,dc=example,dc=com'
        expected = 'uid=John Smith\n,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'with uppercase characters' do
      # We may need to normalize casing at some point.
      # I am just making it explicit that we don't at this time.
      it 'returns the DN with unmodified casing' do
        given    = 'UID=John Smith,ou=People,dc=example,dc=com'
        expected = 'UID=John Smith,ou=People,dc=example,dc=com'
        expect(described_class.normalize_dn(given)).to eq(expected)
      end
    end

    context 'with a malformed DN' do
      context 'when passed a UID instead of a DN' do
        it 'returns the UID (with whitespace stripped)' do
          given    = '  John C. Smith '
          expected = 'John C. Smith'
          expect(described_class.normalize_dn(given)).to eq(expected)
        end
      end

      context 'when an equal sign is escaped' do
        it 'returns the DN completely unmodified' do
          given    = 'uid= foo\\=bar'
          expected = 'uid= foo\\=bar'
          expect(described_class.normalize_dn(given)).to eq(expected)
        end
      end
    end
  end

  describe '#name' do
    it 'uses the configured name attribute and handles values as an array' do
      name = 'John Doe'
      entry['cn'] = [name]
      person = described_class.new(entry, 'ldapmain')

      expect(person.name).to eq(name)
    end
  end

  describe '#email' do
    it 'returns the value of mail, if present' do
      mail = 'john@example.com'
      entry['mail'] = mail
      person = described_class.new(entry, 'ldapmain')

      expect(person.email).to eq([mail])
    end

    it 'returns the value of userPrincipalName, if mail and email are not present' do
      user_principal_name = 'john.doe@example.com'
      entry['userPrincipalName'] = user_principal_name
      person = described_class.new(entry, 'ldapmain')

      expect(person.email).to eq([user_principal_name])
    end
  end
end
