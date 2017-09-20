require 'spec_helper'

describe Gitlab::LDAP::DN do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize' do
    subject { described_class.new(given).to_s_normalized }

    # Regarding the telephoneNumber test:
    #
    # I am not sure whether a space after the telephoneNumber plus sign is valid,
    # and I am not sure if this is "proper" behavior under these conditions, and
    # I am not sure if it matters to us or anyone else, so rather than dig
    # through RFCs, I am only documenting the behavior here.
    where(:test_description, :given, :expected) do
      'strips extraneous whitespace'                                                                 | 'uid     =John Smith ,  ou = People, dc=  example,dc =com'                                            | 'uid=john smith,ou=people,dc=example,dc=com'
      'strips extraneous whitespace for a DN with a single RDN'                                      | 'uid  =  John Smith'                                                                                  | 'uid=john smith'
      'strips extraneous whitespace without changing escaped characters'                             | 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com' | 'uid=sebasti\\c3\\a1n\\ c.\\20smith\\ ,ou=people (aka. \\22humans\\"),dc=example,dc=com'
      'strips extraneous whitespace without modifying the multivalued RDN'                           | 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com'              | 'uid=john smith+telephonenumber=+1 555-555-5555,ou=people,dc=example,dc=com'
      'strips the space after the plus sign in the telephoneNumber'                                  | 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com'             | 'uid=john smith+telephonenumber=+1 555-555-5555,ou=people,dc=example,dc=com'
      'downcases the whole string'                                                                   | 'UID=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=john smith,ou=people,dc=example,dc=com'
      'for a null DN (empty string), returns empty string and does not error'                        | ''                                                                                                    | ''
      'does not strip an escaped leading space in an attribute value'                                | 'uid=\\ John Smith,ou=People,dc=example,dc=com'                                                       | 'uid=\\ john smith,ou=people,dc=example,dc=com'
      'does not strip an escaped trailing space in an attribute value'                               | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'                                                       | 'uid=john smith\\ ,ou=people,dc=example,dc=com'
      'does not strip an escaped leading newline in an attribute value'                              | 'uid=\\\nJohn Smith,ou=People,dc=example,dc=com'                                                      | 'uid=\\\njohn smith,ou=people,dc=example,dc=com'
      'does not strip an escaped trailing newline in an attribute value'                             | 'uid=John Smith\\\n,ou=People,dc=example,dc=com'                                                      | 'uid=john smith\\\n,ou=people,dc=example,dc=com'
      'does not strip an unescaped leading newline (actually an invalid DN)'                         | 'uid=\nJohn Smith,ou=People,dc=example,dc=com'                                                                               | 'uid=\njohn smith,ou=people,dc=example,dc=com'
      'does not strip an unescaped trailing newline (actually an invalid DN)'                        | 'uid=John Smith\n ,ou=People,dc=example,dc=com'                                                                              | 'uid=john smith\n,ou=people,dc=example,dc=com'
      'does not strip if no extraneous whitespace'                                                   | 'uid=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=john smith,ou=people,dc=example,dc=com'
      'does not modify an escaped equal sign in an attribute value'                                  | 'uid= foo  \\=  bar'                                                                                  | 'uid=foo  \\=  bar'
      'converts an escaped hex equal sign to an escaped equal sign in an attribute value'            | 'uid= foo  \\3D  bar'                                                                                 | 'uid=foo  \\=  bar'
      'does not modify an escaped comma in an attribute value'                                       | 'uid= John C. Smith, ou=San Francisco\\, CA'                                                          | 'uid=john c. smith,ou=san francisco\\, ca'
      'converts an escaped hex comma to an escaped comma in an attribute value'                      | 'uid= John C. Smith, ou=San Francisco\\2C CA'                                                         | 'uid=john c. smith,ou=san francisco\\, ca'
      'does not modify an escaped hex carriage return character in an attribute value'               | 'uid= John C. Smith, ou=San Francisco\\,\\0DCA'                                                       | 'uid=john c. smith,ou=san francisco\\,\\0dca'
      'does not modify an escaped hex line feed character in an attribute value'                     | 'uid= John C. Smith, ou=San Francisco\\,\\0ACA'                                                       | 'uid=john c. smith,ou=san francisco\\,\\0aca'
      'does not modify an escaped hex CRLF in an attribute value'                                    | 'uid= John C. Smith, ou=San Francisco\\,\\0D\\0ACA'                                                   | 'uid=john c. smith,ou=san francisco\\,\\0d\\0aca'
    end

    with_them do
      it 'normalizes the DN' do
        assert_generic_test(test_description, subject, expected)
      end
    end

    context 'when the given DN is malformed' do
      let(:given) { 'uid\\=john' }

      it 'raises MalformedDnError' do
        expect(subject).to raise_error(MalformedDnError)
      end
    end
  end

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: #{expected}\n         got: #{got}"
    expect(got).to eq(expected), test_failure_message
  end
end
