# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Ldap::DN do
  using RSpec::Parameterized::TableSyntax

  describe '#normalize_value' do
    subject { described_class.normalize_value(given) }

    it_behaves_like 'normalizes a DN attribute value'

    context 'when the given DN is malformed' do
      context 'when ending with a comma' do
        let(:given) { 'John Smith,' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'when given a BER encoded attribute value with a space in it' do
        let(:given) { '#aa aa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the end of an attribute value, but got \"a\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '#aaXaaa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the first character of a hex pair, but got \"X\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '#aaaYaa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the second character of a hex pair, but got \"Y\"")
        end
      end

      context 'when given a hex pair with a non-hex character in it, inside double quotes' do
        let(:given) { '"Sebasti\\cX\\a1n"' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the second character of a hex pair inside a double quoted value, but got \"X\"")
        end
      end

      context 'with an open (as opposed to closed) double quote' do
        let(:given) { '"James' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'with an invalid escaped hex code' do
        let(:given) { 'J\ames' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Invalid escaped hex code "\am"')
        end
      end

      context 'with a value ending with the escape character' do
        let(:given) { 'foo\\' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end
    end
  end

  describe '#to_normalized_s' do
    subject { described_class.new(given).to_normalized_s }

    it_behaves_like 'normalizes a DN'

    context 'when we do not support the given DN format' do
      context 'multivalued RDNs' do
        context 'without extraneous whitespace' do
          let(:given) { 'uid=john smith+telephonenumber=+1 555-555-5555,ou=people,dc=example,dc=com' }

          it 'raises UnsupportedError' do
            expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::UnsupportedError)
          end
        end

        context 'with extraneous whitespace' do
          context 'around the phone number plus sign' do
            let(:given) { 'uid = John Smith  + telephoneNumber  = + 1 555-555-5555 , ou = People,dc=example,dc=com' }

            it 'raises UnsupportedError' do
              expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::UnsupportedError)
            end
          end

          context 'not around the phone number plus sign' do
            let(:given) { 'uid = John Smith  + telephoneNumber  = +1 555-555-5555 , ou = People,dc=example,dc=com' }

            it 'raises UnsupportedError' do
              expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::UnsupportedError)
            end
          end
        end
      end
    end

    context 'when the given DN is malformed' do
      context 'when ending with a comma' do
        let(:given) { 'uid=John Smith,' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'when given a BER encoded attribute value with a space in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aa aa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the end of an attribute value, but got \"a\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aaXaaa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the first character of a hex pair, but got \"X\"")
        end
      end

      context 'when given a BER encoded attribute value with a non-hex character in it' do
        let(:given) { '0.9.2342.19200300.100.1.25=#aaaYaa' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the second character of a hex pair, but got \"Y\"")
        end
      end

      context 'when given a hex pair with a non-hex character in it, inside double quotes' do
        let(:given) { 'uid="Sebasti\\cX\\a1n"' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, "Expected the second character of a hex pair inside a double quoted value, but got \"X\"")
        end
      end

      context 'without a name value pair' do
        let(:given) { 'John' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'with an open (as opposed to closed) double quote' do
        let(:given) { 'cn="James' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'with an invalid escaped hex code' do
        let(:given) { 'cn=J\ames' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Invalid escaped hex code "\am"')
        end
      end

      context 'with a value ending with the escape character' do
        let(:given) { 'cn=\\' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'DN string ended unexpectedly')
        end
      end

      context 'with an invalid OID attribute type name' do
        let(:given) { '1.2.d=Value' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Unrecognized RDN OID attribute type name character "d"')
        end
      end

      context 'with a period in a non-OID attribute type name' do
        let(:given) { 'd1.2=Value' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Unrecognized RDN attribute type name character "."')
        end
      end

      context 'when starting with non-space, non-alphanumeric character' do
        let(:given) { ' -uid=John Smith' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Unrecognized first character of an RDN attribute type name "-"')
        end
      end

      context 'when given a UID with an escaped equal sign' do
        let(:given) { 'uid\\=john' }

        it 'raises MalformedError' do
          expect { subject }.to raise_error(Gitlab::Auth::Ldap::DN::MalformedError, 'Unrecognized RDN attribute type name character "\\"')
        end
      end
    end
  end

  def assert_generic_test(test_description, got, expected)
    test_failure_message = "Failed test description: '#{test_description}'\n\n    expected: \"#{expected}\"\n         got: \"#{got}\""
    expect(got).to eq(expected), test_failure_message
  end
end
