require 'spec_helper'

describe Gitlab::LDAP::Person do
  using RSpec::Parameterized::TableSyntax
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

  describe '.normalize_uid_or_dn' do
    context 'given a DN' do
      # Regarding the telephoneNumber test:
      #
      # I am not sure whether a space after the telephoneNumber plus sign is valid,
      # and I am not sure if this is "proper" behavior under these conditions, and
      # I am not sure if it matters to us or anyone else, so rather than dig
      # through RFCs, I am only documenting the behavior here.
      where(:test_description, :given, :expected) do
        'strips extraneous whitespace'                                                               | 'uid     =John Smith ,  ou = People, dc=  example,dc =com'                                            | 'uid=John Smith,ou=People,dc=example,dc=com'
        'strips extraneous whitespace for a DN with a single RDN'                                    | 'uid  =  John Smith'                                                                                  | 'uid=John Smith'
        'strips extraneous whitespace without changing escaped characters'                           | 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com' | 'uid=Sebasti\\c3\\a1n\\ C.\\20Smith\\ ,ou=People (aka. \\22humans\\"),dc=example,dc=com'
        'strips extraneous whitespace without modifying the multivalued RDN'                         | 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com'              | 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
        'strips the space after the plus sign in the telephoneNumber'                                | 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com'             | 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
        'for a null DN (empty string), returns empty string and does not error'                      | ''                                                                                                    | ''
        'does not strip the escaped leading space in an attribute value (and does not error like Net::LDAP::DN.new does)' | 'uid=\\ John Smith,ou=People,dc=example,dc=com'                                  | 'uid=\\ John Smith,ou=People,dc=example,dc=com'
        'does not strip the escaped trailing space in an attribute value'                            | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'                                                       | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'
        'does not strip the escaped leading newline in an attribute value'                           | 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'                                                      | 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'
        'does not strip the escaped trailing newline in an attribute value'                          | 'uid=John Smith\\\n,ou=People,dc=example,dc=com'                                                      | 'uid=John Smith\\\n,ou=People,dc=example,dc=com'
        'does not strip the unescaped leading newline in an attribute value'                         | 'uid=\nJohn Smith,ou=People,dc=example,dc=com'                                                        | 'uid=\nJohn Smith,ou=People,dc=example,dc=com'
        'does not strip the unescaped trailing newline in an attribute value'                        | 'uid=John Smith\n ,ou=People,dc=example,dc=com'                                                       | 'uid=John Smith\n,ou=People,dc=example,dc=com'
        'does not modify casing'                                                                     | 'UID=John Smith,ou=People,dc=example,dc=com'                                                          | 'UID=John Smith,ou=People,dc=example,dc=com'
        'does not strip non whitespace'                                                              | 'uid=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=John Smith,ou=People,dc=example,dc=com'
        'does not treat escaped equal signs as attribute delimiters'                                 | 'uid= foo  \\=  bar'                                                                                  | 'uid=foo  \\=  bar'
        'does not treat escaped hex equal signs as attribute delimiters'                             | 'uid= foo  \\3D  bar'                                                                                 | 'uid=foo  \\3D  bar'
        'does not treat escaped commas as attribute delimiters'                                      | 'uid= John C. Smith, ou=San Francisco\\, CA'                                                          | 'uid=John C. Smith,ou=San Francisco\\, CA'
        'does not treat escaped hex commas as attribute delimiters'                                  | 'uid= John C. Smith, ou=San Francisco\\2C CA'                                                         | 'uid=John C. Smith,ou=San Francisco\\2C CA'
      end

      with_them do
        it 'normalizes the DN' do
          assert_generic_test(test_description, described_class.normalize_uid_or_dn(given), expected)
        end
      end
    end

    context 'given a UID' do
      where(:test_description, :given, :expected) do
        'strips extraneous whitespace'                                        | ' John C. Smith   '                     | 'John C. Smith'
        'strips extraneous whitespace without changing escaped characters'    | '  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ' | 'Sebasti\\c3\\a1n\\ C.\\20Smith\\ '
        'does not strip the escaped leading space in an attribute value'      | '   \\ John Smith '                     | '\\ John Smith'
        'does not strip the escaped trailing space in an attribute value'     | '    John Smith\\   '                   | 'John Smith\\ '
        'does not strip the escaped leading newline in an attribute value'    | '     \\\nJohn Smith  '                 | '\\\nJohn Smith'
        'does not strip the escaped trailing newline in an attribute value'   | '    John Smith\\\n  '                  | 'John Smith\\\n'
        'does not strip the unescaped leading newline in an attribute value'  | '   \nJohn Smith '                      | '\nJohn Smith'
        'does not strip the unescaped trailing newline in an attribute value' | '  John Smith\n   '                     | 'John Smith\n'
        'does not modify casing'                                              | ' John Smith  '                         | 'John Smith'
        'does not strip non whitespace'                                       | 'John Smith'                            | 'John Smith'
        'does not treat escaped equal signs as attribute delimiters'          | ' foo  \\=  bar'                        | 'foo  \\=  bar'
        'does not treat escaped hex equal signs as attribute delimiters'      | ' foo  \\3D  bar'                       | 'foo  \\3D  bar'
        'does not treat escaped commas as attribute delimiters'               | ' Smith\\, John C.'                     | 'Smith\\, John C.'
        'does not treat escaped hex commas as attribute delimiters'           | ' Smith\\2C John C.'                    | 'Smith\\2C John C.'
      end

      with_them do
        it 'normalizes the UID' do
          assert_generic_test(test_description, described_class.normalize_uid_or_dn(given), expected)
        end
      end
    end
  end

  describe '.normalize_uid' do
    context 'given a UID' do
      where(:test_description, :given, :expected) do
        'strips extraneous whitespace'                                        | ' John C. Smith   '                     | 'John C. Smith'
        'strips extraneous whitespace without changing escaped characters'    | '  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ' | 'Sebasti\\c3\\a1n\\ C.\\20Smith\\ '
        'does not strip the escaped leading space in an attribute value'      | '   \\ John Smith '                     | '\\ John Smith'
        'does not strip the escaped trailing space in an attribute value'     | '    John Smith\\   '                   | 'John Smith\\ '
        'does not strip the escaped leading newline in an attribute value'    | '     \\\nJohn Smith  '                 | '\\\nJohn Smith'
        'does not strip the escaped trailing newline in an attribute value'   | '    John Smith\\\n  '                  | 'John Smith\\\n'
        'does not strip the unescaped leading newline in an attribute value'  | '   \nJohn Smith '                      | '\nJohn Smith'
        'does not strip the unescaped trailing newline in an attribute value' | '  John Smith\n   '                     | 'John Smith\n'
        'does not modify casing'                                              | ' John Smith  '                         | 'John Smith'
        'does not strip non whitespace'                                       | 'John Smith'                            | 'John Smith'
        'does not treat escaped equal signs as attribute delimiters'          | ' foo  \\=  bar'                        | 'foo  \\=  bar'
        'does not treat escaped hex equal signs as attribute delimiters'      | ' foo  \\3D  bar'                       | 'foo  \\3D  bar'
        'does not treat escaped commas as attribute delimiters'               | ' Smith\\, John C.'                     | 'Smith\\, John C.'
        'does not treat escaped hex commas as attribute delimiters'           | ' Smith\\2C John C.'                    | 'Smith\\2C John C.'
      end

      with_them do
        it 'normalizes the UID' do
          assert_generic_test(test_description, described_class.normalize_uid(given), expected)
        end
      end
    end
  end

  describe '.normalize_dn' do
    # Regarding the telephoneNumber test:
    #
    # I am not sure whether a space after the telephoneNumber plus sign is valid,
    # and I am not sure if this is "proper" behavior under these conditions, and
    # I am not sure if it matters to us or anyone else, so rather than dig
    # through RFCs, I am only documenting the behavior here.
    where(:test_description, :given, :expected) do
      'strips extraneous whitespace'                                                               | 'uid     =John Smith ,  ou = People, dc=  example,dc =com'                                            | 'uid=John Smith,ou=People,dc=example,dc=com'
      'strips extraneous whitespace for a DN with a single RDN'                                    | 'uid  =  John Smith'                                                                                  | 'uid=John Smith'
      'strips extraneous whitespace without changing escaped characters'                           | 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com' | 'uid=Sebasti\\c3\\a1n\\ C.\\20Smith\\ ,ou=People (aka. \\22humans\\"),dc=example,dc=com'
      'strips extraneous whitespace without modifying the multivalued RDN'                         | 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com'              | 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
      'strips the space after the plus sign in the telephoneNumber'                                | 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com'             | 'uid=John Smith+telephoneNumber=+1 555-555-5555,ou=People,dc=example,dc=com'
      'for a null DN (empty string), returns empty string and does not error'                      | ''                                                                                                    | ''
      'does not strip the escaped leading space in an attribute value (and does not error like Net::LDAP::DN.new does)' | 'uid=\\ John Smith,ou=People,dc=example,dc=com'                                                       | 'uid=\\ John Smith,ou=People,dc=example,dc=com'
      'does not strip the escaped trailing space in an attribute value'                            | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'                                                       | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'
      'does not strip the escaped leading newline in an attribute value'                           | 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'                                                      | 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'
      'does not strip the escaped trailing newline in an attribute value'                          | 'uid=John Smith\\\n,ou=People,dc=example,dc=com'                                                      | 'uid=John Smith\\\n,ou=People,dc=example,dc=com'
      'does not strip the unescaped leading newline in an attribute value'                         | 'uid=\nJohn Smith,ou=People,dc=example,dc=com'                                                        | 'uid=\nJohn Smith,ou=People,dc=example,dc=com'
      'does not strip the unescaped trailing newline in an attribute value'                        | 'uid=John Smith\n ,ou=People,dc=example,dc=com'                                                       | 'uid=John Smith\n,ou=People,dc=example,dc=com'
      'does not modify casing'                                                                     | 'UID=John Smith,ou=People,dc=example,dc=com'                                                          | 'UID=John Smith,ou=People,dc=example,dc=com'
      'does not strip non whitespace'                                                              | 'uid=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=John Smith,ou=People,dc=example,dc=com'
      'does not treat escaped equal signs as attribute delimiters'                                 | 'uid= foo  \\=  bar'                                                                                  | 'uid=foo  \\=  bar'
      'does not treat escaped hex equal signs as attribute delimiters'                             | 'uid= foo  \\3D  bar'                                                                                 | 'uid=foo  \\3D  bar'
      'does not treat escaped commas as attribute delimiters'                                      | 'uid= John C. Smith, ou=San Francisco\\, CA'                                                          | 'uid=John C. Smith,ou=San Francisco\\, CA'
      'does not treat escaped hex commas as attribute delimiters'                                  | 'uid= John C. Smith, ou=San Francisco\\2C CA'                                                         | 'uid=John C. Smith,ou=San Francisco\\2C CA'
    end

    with_them do
      it 'normalizes the DN' do
        assert_generic_test(test_description, described_class.normalize_dn(given), expected)
      end
    end
  end

  describe '.is_dn?' do
    where(:test_description, :given, :expected) do
      'given a DN with a single RDN'                     | 'uid=John C. Smith'                                 | true
      'given a DN with multiple RDNs'                    | 'uid=John C. Smith,ou=People,dc=example,dc=com'     | true
      'given a UID'                                      | 'John C. Smith'                                     | false
      'given a DN with a single RDN with excess spaces'  | ' uid=John C. Smith   '                             | true
      'given a DN with multiple RDNs with excess spaces' | '  uid=John C. Smith,ou=People,dc=example,dc=com  ' | true
      'given a UID with excess spaces'                   | '   John C. Smith '                                 | false
      'given a DN with an escaped equal sign'            | 'uid=John C. Smith,ou=People\\='                    | true
      'given a DN with an equal sign in escaped hex'     | 'uid=John C. Smith,ou=People\\3D'                   | true
    end

    with_them do
      it 'returns the expected boolean' do
        assert_generic_test(test_description, described_class.is_dn?(given), expected)
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

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: #{expected}\n         got: #{got}"
    expect(got).to eq(expected), test_failure_message
  end
end
