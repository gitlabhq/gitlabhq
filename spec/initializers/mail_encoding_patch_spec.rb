# frozen_string_literal: true
# rubocop:disable RSpec/VariableDefinition, RSpec/VariableName

require 'spec_helper'
require 'mail'
require_relative '../../config/initializers/mail_encoding_patch'

RSpec.describe 'Mail quoted-printable transfer encoding patch and Unicode characters' do
  include FixtureHelpers

  shared_examples 'email encoding' do |email|
    it 'enclosing in a new object does not change the encoded original' do
      new_email = Mail.new(email)

      expect(new_email.subject).to eq(email.subject)
      expect(new_email.from).to eq(email.from)
      expect(new_email.to).to eq(email.to)
      expect(new_email.content_type).to eq(email.content_type)
      expect(new_email.content_transfer_encoding).to eq(email.content_transfer_encoding)

      expect(new_email.encoded).to eq(email.encoded)
    end
  end

  context 'with a text email' do
    context 'with a body that encodes to exactly 74 characters (final newline)' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/plain; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "-123456789-123456789-123456789-123456789-123456789-123456789-123456789-1\n"
      end

      it_behaves_like 'email encoding', email
    end

    context 'with a body that encodes to exactly 74 characters (no final newline)' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/plain; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "-123456789-123456789-123456789-123456789-123456789-123456789-123456789-12"
      end

      it_behaves_like 'email encoding', email
    end

    context 'with a body that encodes to exactly 75 characters' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/plain; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "-123456789-123456789-123456789-123456789-123456789-123456789-123456789-12\n"
      end

      it_behaves_like 'email encoding', email
    end
  end

  context 'with an html email' do
    context 'with a body that encodes to exactly 74 characters (final newline)' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/html; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "<p>-123456789-123456789-123456789-123456789-123456789-123456789-1234</p>\n"
      end

      it_behaves_like 'email encoding', email
    end

    context 'with a body that encodes to exactly 74 characters (no final newline)' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/html; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "<p>-123456789-123456789-123456789-123456789-123456789-123456789-12345</p>"
      end

      it_behaves_like 'email encoding', email
    end

    context 'with a body that encodes to exactly 75 characters' do
      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
        content_type 'text/html; charset=UTF-8'
        content_transfer_encoding 'quoted-printable'
        body "<p>-123456789-123456789-123456789-123456789-123456789-123456789-12345</p>\n"
      end

      it_behaves_like 'email encoding', email
    end
  end

  context 'a multipart email' do
    email = Mail.new do
      to 'jane.doe@example.com'
      from 'John Dóe <john.doe@example.com>'
      subject 'Encoding tést'
    end

    text_part = Mail::Part.new do
      content_type 'text/plain; charset=UTF-8'
      content_transfer_encoding 'quoted-printable'
      body "\r\n\r\n@john.doe, now known as John Dóe has accepted your invitation to join the Administrator / htmltest project.\r\n\r\nhttp://169.254.169.254:3000/root/htmltest\r\n\r\n-- \r\nYou're receiving this email because of your account on 169.254.169.254.\r\n\r\n\r\n\r\n"
    end

    html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      content_transfer_encoding 'quoted-printable'
      body "\r\n\r\n@john.doe, now known as John Dóe has accepted your invitation to join the Administrator / htmltest project.\r\n\r\nhttp://169.254.169.254:3000/root/htmltest\r\n\r\n-- \r\nYou're receiving this email because of your account on 169.254.169.254.\r\n\r\n\r\n\r\n"
    end

    email.text_part = text_part
    email.html_part = html_part

    it_behaves_like 'email encoding', email
  end

  context 'with non UTF-8 charset' do
    email = Mail.new do
      to 'jane.doe@example.com'
      from 'John Dóe <john.doe@example.com>'
      subject 'Encoding tést'
      content_type 'text/plain; charset=windows-1251'
      content_transfer_encoding 'quoted-printable'
      body "This line is very long and will be put in multiple quoted-printable lines. Some Russian character: Д\n\n\n".encode('windows-1251')
    end

    it_behaves_like 'email encoding', email

    it 'can be decoded back' do
      expect(Mail.new(email).body.decoded.dup.force_encoding('windows-1251').encode('utf-8')).to include('Some Russian character: Д')
    end
  end

  context 'with binary content' do
    context 'can be encoded with \'base64\' content-transfer-encoding' do
      image = File.binread('spec/fixtures/rails_sample.jpg')

      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
      end

      part = Mail::Part.new
      part.body = [image].pack('m')
      part.content_type = 'image/jpg'
      part.content_transfer_encoding = 'base64'

      email.parts << part

      it_behaves_like 'email encoding', email

      it 'binary contents are not modified' do
        expect(email.parts.first.decoded).to eq(image)

        # Enclosing in a new Mail object does not corrupt encoded data
        expect(Mail.new(email).parts.first.decoded).to eq(image)
      end
    end

    context 'encoding fails with \'quoted-printable\' content-transfer-encoding' do
      image = File.binread('spec/fixtures/rails_sample.jpg')

      email = Mail.new do
        to 'jane.doe@example.com'
        from 'John Dóe <john.doe@example.com>'
        subject 'Encoding tést'
      end

      part = Mail::Part.new
      part.body = [image].pack('M*')
      part.content_type = 'image/jpg'
      part.content_transfer_encoding = 'quoted-printable'

      email.parts << part

      # The Mail patch in `config/initializers/mail_encoding_patch.rb` fixes
      # encoding of non-binary content. The failure below is expected since we
      # reverted some upstream changes in order to properly support SMIME signatures
      # See https://gitlab.com/gitlab-org/gitlab/issues/197386
      it 'content cannot be decoded back' do
        # Headers are ok
        expect(email.subject).to eq(email.subject)
        expect(email.from).to eq(email.from)
        expect(email.to).to eq(email.to)
        expect(email.content_type).to eq(email.content_type)
        expect(email.content_transfer_encoding).to eq(email.content_transfer_encoding)

        # Content cannot be recovered
        expect(email.parts.first.decoded).not_to eq(image)
      end
    end
  end

  context 'empty text mail with unsual body encoding' do
    it 'decodes email successfully' do
      email = Mail::Message.new(nil)

      Mail::Encodings.get_all.each do |encoder|
        email.body = nil
        email.body.charset = 'utf-8'
        email.body.encoding = encoder.to_s

        expect { email.encoded }.not_to raise_error
      end
    end
  end

  context 'frozen email boy content with unsual body encoding' do
    let(:content) { fixture_file("emails/ios_default.eml") }

    it 'decodes email successfully' do
      email = Mail::Message.new(content)

      Mail::Encodings.get_all.each do |encoder|
        email.body = content.freeze
        email.body.charset = 'utf-8'
        email.body.encoding = encoder.to_s

        expect { email.encoded }.not_to raise_error
      end
    end
  end
end
# rubocop:enable RSpec/VariableDefinition, RSpec/VariableName
