# frozen_string_literal: true

RSpec.shared_examples 'normalizes a DN' do
  using RSpec::Parameterized::TableSyntax

  where(:test_description, :given, :expected) do
    'strips extraneous whitespace'                                                                 | 'uid     =John Smith ,  ou = People, dc=  example,dc =com'                                            | 'uid=john smith,ou=people,dc=example,dc=com'
    'strips extraneous whitespace for a DN with a single RDN'                                      | 'uid  =  John Smith'                                                                                  | 'uid=john smith'
    'unescapes non-reserved, non-special Unicode characters'                                       | 'uid   =  Sebasti\\c3\\a1n\\ C.\\20Smith,   ou=People (aka. \\22humans\\")  ,dc=example, dc=com'      | 'uid=sebastián c. smith,ou=people (aka. \\"humans\\"),dc=example,dc=com'
    'downcases the whole string'                                                                   | 'UID=John Smith,ou=People,dc=example,dc=com'                                                          | 'uid=john smith,ou=people,dc=example,dc=com'
    'for a null DN (empty string), returns empty string and does not error'                        | ''                                                                                                    | ''
    'does not strip an escaped leading space in an attribute value'                                | 'uid=\\ John Smith,ou=People,dc=example,dc=com'                                                       | 'uid=\\ john smith,ou=people,dc=example,dc=com'
    'does not strip an escaped leading space in the last attribute value'                          | 'uid=\\ John Smith'                                                                                   | 'uid=\\ john smith'
    'does not strip an escaped trailing space in an attribute value'                               | 'uid=John Smith\\ ,ou=People,dc=example,dc=com'                                                       | 'uid=john smith\\ ,ou=people,dc=example,dc=com'
    'strips extraneous spaces after an escaped trailing space'                                     | 'uid=John Smith\\   ,ou=People,dc=example,dc=com'                                                     | 'uid=john smith\\ ,ou=people,dc=example,dc=com'
    'strips extraneous spaces after an escaped trailing space at the end of the DN'                | 'uid=John Smith,ou=People,dc=example,dc=com\\   '                                                     | 'uid=john smith,ou=people,dc=example,dc=com\\ '
    'properly preserves escaped trailing space after unescaped trailing spaces'                    | 'uid=John Smith  \\  ,ou=People,dc=example,dc=com'                                                    | 'uid=john smith  \\ ,ou=people,dc=example,dc=com'
    'preserves multiple inner spaces in an attribute value'                                        | 'uid=John   Smith,ou=People,dc=example,dc=com'                                                        | 'uid=john   smith,ou=people,dc=example,dc=com'
    'preserves inner spaces after an escaped space'                                                | 'uid=John\\   Smith,ou=People,dc=example,dc=com'                                                      | 'uid=john   smith,ou=people,dc=example,dc=com'
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
end

RSpec.shared_examples 'normalizes a DN attribute value' do
  using RSpec::Parameterized::TableSyntax

  where(:test_description, :given, :expected) do
    'strips extraneous whitespace'                                                      | '   John Smith   '                 | 'john smith'
    'unescapes non-reserved, non-special Unicode characters'                            | 'Sebasti\\c3\\a1n\\ C.\\20Smith'   | 'sebastián c. smith'
    'downcases the whole string'                                                        | 'JoHn C. Smith'                    | 'john c. smith'
    'does not strip an escaped leading space in an attribute value'                     | '\\ John Smith'                    | '\\ john smith'
    'does not strip an escaped trailing space in an attribute value'                    | 'John Smith\\ '                    | 'john smith\\ '
    'hex-escapes an escaped leading newline in an attribute value'                      | "\\\nJohn Smith"                   | "\\0ajohn smith"
    'hex-escapes and does not strip an escaped trailing newline in an attribute value'  | "John Smith\\\n"                   | "john smith\\0a"
    'hex-escapes an unescaped leading newline (actually an invalid DN value?)'          | "\nJohn Smith"                     | "\\0ajohn smith"
    'strips an unescaped trailing newline (actually an invalid DN value?)'              | "John Smith\n"                     | "john smith"
    'does not strip if no extraneous whitespace'                                        | 'John Smith'                       | 'john smith'
    'does not modify an escaped equal sign in an attribute value'                       | ' foo  \\=  bar'                   | 'foo  \\=  bar'
    'converts an escaped hex equal sign to an escaped equal sign in an attribute value' | ' foo  \\3D  bar'                  | 'foo  \\=  bar'
    'does not modify an escaped comma in an attribute value'                            | 'San Francisco\\, CA'              | 'san francisco\\, ca'
    'converts an escaped hex comma to an escaped comma in an attribute value'           | 'San Francisco\\2C CA'             | 'san francisco\\, ca'
    'does not modify an escaped hex carriage return character in an attribute value'    | 'San Francisco\\,\\0DCA'           | 'san francisco\\,\\0dca'
    'does not modify an escaped hex line feed character in an attribute value'          | 'San Francisco\\,\\0ACA'           | 'san francisco\\,\\0aca'
    'does not modify an escaped hex CRLF in an attribute value'                         | 'San Francisco\\,\\0D\\0ACA'       | 'san francisco\\,\\0d\\0aca'
  end

  with_them do
    it 'normalizes the DN attribute value' do
      assert_generic_test(test_description, subject, expected)
    end
  end
end
