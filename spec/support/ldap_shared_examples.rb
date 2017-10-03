shared_examples_for 'normalizes a DN attribute value' do
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
