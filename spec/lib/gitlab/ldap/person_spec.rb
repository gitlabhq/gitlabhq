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

  shared_examples_for 'normalizes the UID' do
    where(:test_description, :given, :expected) do
      'strips extraneous whitespace'                                        | ' John C. Smith   '                     | 'john c. smith'
      'strips extraneous whitespace without changing escaped characters'    | '  Sebasti\\c3\\a1n\\ C.\\20Smith\\   ' | 'sebasti\\c3\\a1n\\ c.\\20smith\\ '
      'downcases the whole string'                                          | 'John Smith'                            | 'john smith'
      'does not strip the escaped leading space in an attribute value'      | '   \\ John Smith '                     | '\\ john smith'
      'does not strip the escaped trailing space in an attribute value'     | '    John Smith\\   '                   | 'john smith\\ '
      'does not strip the escaped leading newline in an attribute value'    | '     \\\nJohn Smith  '                 | '\\\njohn smith'
      'does not strip the escaped trailing newline in an attribute value'   | '    John Smith\\\n  '                  | 'john smith\\\n'
      'does not strip the unescaped leading newline in an attribute value'  | '   \nJohn Smith '                      | '\njohn smith'
      'does not strip the unescaped trailing newline in an attribute value' | '  John Smith\n   '                     | 'john smith\n'
      'does not strip non whitespace'                                       | 'John Smith'                            | 'john smith'
      'does not treat escaped equal signs as attribute delimiters'          | ' foo  \\=  bar'                        | 'foo  \\=  bar'
      'does not treat escaped hex equal signs as attribute delimiters'      | ' foo  \\3D  bar'                       | 'foo  \\3d  bar'
      'does not treat escaped commas as attribute delimiters'               | ' Smith\\, John C.'                     | 'smith\\, john c.'
      'does not treat escaped hex commas as attribute delimiters'           | ' Smith\\2C John C.'                    | 'smith\\2c john c.'
    end

    with_them do
      it 'normalizes the UID' do
        assert_generic_test(test_description, subject, expected)
      end
    end
  end

  describe '.normalize_uid' do
    subject { described_class.normalize_uid(given) }

    it_behaves_like 'normalizes the UID'

    context 'with an exception during normalization' do
      let(:given) { described_class } # just something that will cause an exception

      it 'returns the given UID unmodified' do
        expect(subject).to eq(given)
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
