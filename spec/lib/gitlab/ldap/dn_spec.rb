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
      'unescapes non-reserved, non-special Unicode characters'                                       | 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com' | 'uid=sebastián c. smith  \\ ,ou=people (aka. \\"humans\\"),dc=example,dc=com'
      'downcases the whole string'                                                                   | 'UID=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=john smith,ou=people,dc=example,dc=com'
      'for a null DN (empty string), returns empty string and does not error'                        | ''                                                                                                    | ''
      'does not strip an escaped leading space in an attribute value'                                | 'uid=\\ John Smith,ou=People,dc=example,dc=com'                                                       | 'uid=\\ john smith,ou=people,dc=example,dc=com'
      'does not strip an escaped trailing space in an attribute value'                               | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'                                                       | 'uid=john smith\\ ,ou=people,dc=example,dc=com'
      'hex-escapes an escaped leading newline in an attribute value'                                 | "uid=\\\nJohn Smith,ou=People,dc=example,dc=com"                                                      | "uid=\\0ajohn smith,ou=people,dc=example,dc=com"
      'hex-escapes and does not strip an escaped trailing newline in an attribute value'             | "uid=John Smith\\\n,ou=People,dc=example,dc=com"                                                      | "uid=john smith\\0a,ou=people,dc=example,dc=com"
      'hex-escapes an unescaped leading newline (actually an invalid DN?)'                           | "uid=\nJohn Smith,ou=People,dc=example,dc=com"                                                        | "uid=\\0ajohn smith,ou=people,dc=example,dc=com"
      'strips an unescaped trailing newline (actually an invalid DN?)'                               | "uid=John Smith\n,ou=People,dc=example,dc=com"                                                        | "uid=john smith,ou=people,dc=example,dc=com"
      'does not strip if no extraneous whitespace'                                                   | 'uid=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=john smith,ou=people,dc=example,dc=com'
      'does not modify an escaped equal sign in an attribute value'                                  | 'uid= foo  \\=  bar'                                                                                  | 'uid=foo  \\=  bar'
      'converts an escaped hex equal sign to an escaped equal sign in an attribute value'            | 'uid= foo  \\3D  bar'                                                                                 | 'uid=foo  \\=  bar'
      'does not modify an escaped comma in an attribute value'                                       | 'uid= John C. Smith, ou=San Francisco\\, CA'                                                          | 'uid=john c. smith,ou=san francisco\\, ca'
      'converts an escaped hex comma to an escaped comma in an attribute value'                      | 'uid= John C. Smith, ou=San Francisco\\2C CA'                                                         | 'uid=john c. smith,ou=san francisco\\, ca'
      'does not modify an escaped hex carriage return character in an attribute value'               | 'uid= John C. Smith, ou=San Francisco\\,\\0DCA'                                                       | 'uid=john c. smith,ou=san francisco\\,\\0dca'
      'does not modify an escaped hex line feed character in an attribute value'                     | 'uid= John C. Smith, ou=San Francisco\\,\\0ACA'                                                       | 'uid=john c. smith,ou=san francisco\\,\\0aca'
      'does not modify an escaped hex CRLF in an attribute value'                                    | 'uid= John C. Smith, ou=San Francisco\\,\\0D\\0ACA'                                                   | 'uid=john c. smith,ou=san francisco\\,\\0d\\0aca'
      'allows attribute type name OIDs'                                                              | '0.9.2342.19200300.100.1.25=Example,0.9.2342.19200300.100.1.25=Com'                                   | '0.9.2342.19200300.100.1.25=example,0.9.2342.19200300.100.1.25=com'
      'strips extraneous whitespace from attribute type name OIDs'                                   | '0.9.2342.19200300.100.1.25 = Example, 0.9.2342.19200300.100.1.25 = Com'                              | '0.9.2342.19200300.100.1.25=example,0.9.2342.19200300.100.1.25=com'
    end

    with_them do
      it 'normalizes the DN' do
        assert_generic_test(test_description, subject, expected)
      end
    end

    context 'when we do not support the given DN format' do
      context 'multivalued RDNs' do
        context 'without extraneous whitespace' do
          let(:given) { 'uid=john smith+telephonenumber=+1 555-555-5555,ou=people,dc=example,dc=com' }

          it 'raises UnsupportedDnFormatError' do
            expect{ subject }.to raise_error(Gitlab::LDAP::UnsupportedDnFormatError)
          end
        end

        context 'with extraneous whitespace' do
          context 'around the phone number plus sign' do
            let(:given) { 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com' }

            it 'raises UnsupportedDnFormatError' do
              expect{ subject }.to raise_error(Gitlab::LDAP::UnsupportedDnFormatError)
            end
          end

          context 'not around the phone number plus sign' do
            let(:given) { 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com' }

            it 'raises UnsupportedDnFormatError' do
              expect{ subject }.to raise_error(Gitlab::LDAP::UnsupportedDnFormatError)
            end
          end
        end
      end
    end

    context 'when the given DN is malformed' do
      context 'when ending with a comma' do
        let(:given) { 'uid=John Smith,' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'DN string ended unexpectedly')
        end
      end

      context 'when given a BER encoded attribute value with a space in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aa aa' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, "Expected the end of an attribute value, but got \"a\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aaXaaa' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, "Expected the first character of a hex pair, but got \"x\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aaaYaa' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, "Expected the second character of a hex pair, but got \"y\"")
        end
      end

      context 'when given a hex pair with a non-hex character in it, inside double quotes' do
        let(:given) { 'uid="Sebasti\\cX\\a1n"' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, "Expected the second character of a hex pair inside a double quoted value, but got \"x\"")
        end
      end

      context 'without a name value pair' do
        let(:given) { 'John' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'DN string ended unexpectedly')
        end
      end

      context 'with an open (as opposed to closed) double quote' do
        let(:given) { 'cn="James' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'DN string ended unexpectedly')
        end
      end

      context 'with an invalid escaped hex code' do
        let(:given) { 'cn=J\ames' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'Invalid escaped hex code "\am"')
        end
      end

      context 'with a value ending with the escape character' do
        let(:given) { 'cn=\\' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'DN string ended unexpectedly')
        end
      end

      context 'with an invalid OID attribute type name' do
        let(:given) { '1.2.d=Value' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'Unrecognized RDN OID attribute type name character "d"')
        end
      end

      context 'with a period in a non-OID attribute type name' do
        let(:given) { 'd1.2=Value' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'Unrecognized RDN attribute type name character "."')
        end
      end

      context 'when starting with non-space, non-alphanumeric character' do
        let(:given) { ' -uid=John Smith' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'Unrecognized first character of an RDN attribute type name "-"')
        end
      end

      context 'when given a UID with an escaped equal sign' do
        let(:given) { 'uid\\=john' }

        it 'raises MalformedDnError' do
          expect{ subject }.to raise_error(Gitlab::LDAP::MalformedDnError, 'Unrecognized RDN attribute type name character "\\"')
        end
      end
    end
  end

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: \"#{expected}\"\n         got: \"#{got}\""
    expect(got).to eq(expected), test_failure_message
  end
end
