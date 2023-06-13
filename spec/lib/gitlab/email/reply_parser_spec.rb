# frozen_string_literal: true

require "spec_helper"

# Inspired in great part by Discourse's Email::Receiver
RSpec.describe Gitlab::Email::ReplyParser, feature_category: :team_planning do
  describe '#execute' do
    def test_parse_body(mail_string, params = {})
      described_class.new(Mail::Message.new(mail_string), **params).execute
    end

    it "returns an empty string if the message is blank" do
      expect(test_parse_body("")).to eq("")
    end

    it "returns an empty string if the message is not an email" do
      expect(test_parse_body("asdf" * 30)).to eq("")
    end

    it "returns an empty string if there is no reply content" do
      expect(test_parse_body(fixture_file("emails/no_content_reply.eml"))).to eq("")
    end

    context 'when allow_only_quotes is true' do
      it "returns quoted text from email" do
        text = test_parse_body(fixture_file("emails/no_content_reply.eml"), allow_only_quotes: true)

        expect(text).to eq(
          <<-BODY.strip_heredoc.chomp
            >
            >
            >
            > eviltrout posted in 'Adventure Time Sux' on Discourse Meta:
            >
            > ---
            > hey guys everyone knows adventure time sucks!
            >
            > ---
            > Please visit this link to respond: http://localhost:3000/t/adventure-time-sux/1234/3
            >
            > To unsubscribe from these emails, visit your [user preferences](http://localhost:3000/user_preferences).
            >
          BODY
        )
      end
    end

    it "properly renders plaintext-only email" do
      expect(test_parse_body(fixture_file("emails/plaintext_only.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### reply from default mail client in Windows 8.1 Metro


            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.


            This is a **bold** word in Markdown


            This is a link http://example.com
          BODY
        )
    end

    it "properly renders html-only email with table and blockquote" do
      expect(test_parse_body(fixture_file("emails/html_table_and_blockquote.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            Company	Contact	Country
            Alfreds Futterkiste	Maria Anders	Germany
            Centro comercial Moctezuma	Francisco Chang	Mexico
            Words can be like X-rays, if you use them properly—they’ll go through anything. You read and you’re pierced.
          BODY
        )
    end

    it "supports a Dutch reply" do
      expect(test_parse_body(fixture_file("emails/dutch.eml"))).to eq("Dit is een antwoord in het Nederlands.")
    end

    it "removes an 'on date wrote' quoting line" do
      expect(test_parse_body(fixture_file("emails/on_wrote.eml"))).to eq("Sure, all you need to do is frobnicate the foobar and you'll be all set!")
    end

    it "handles multiple paragraphs" do
      expect(test_parse_body(fixture_file("emails/paragraphs.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            Is there any reason the *old* candy can't be kept in silos while the new candy
            is imported into *new* silos?

            The thing about candy is it stays delicious for a long time -- we can just keep
            it there without worrying about it too much, imo.

            Thanks for listening.
          BODY
        )
    end

    it "handles multiple paragraphs when parsing html" do
      expect(test_parse_body(fixture_file("emails/html_paragraphs.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            Awesome!

            Pleasure to have you here!

            :boom:
          BODY
        )
    end

    it "handles newlines" do
      expect(test_parse_body(fixture_file("emails/newlines.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            This is my reply.
            It is my best reply.
            It will also be my *only* reply.
          BODY
        )
    end

    it "handles inline reply" do
      expect(test_parse_body(fixture_file("emails/inline_reply.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            >     techAPJ <https://meta.discourse.org/users/techapj>
            > November 28
            >
            > Test reply.
            >
            > First paragraph.
            >
            > Second paragraph.
            >
            > To respond, reply to this email or visit
            > https://meta.discourse.org/t/testing-default-email-replies/22638/3 in
            > your browser.
            >  ------------------------------
            > Previous Replies    codinghorror
            > <https://meta.discourse.org/users/codinghorror>
            > November 28
            >
            > We're testing the latest GitHub email processing library which we are
            > integrating now.
            >
            > https://github.com/github/email_reply_parser
            >
            > Go ahead and reply to this topic and I'll reply from various email clients
            > for testing.
            >   ------------------------------
            >
            > To respond, reply to this email or visit
            > https://meta.discourse.org/t/testing-default-email-replies/22638/3 in
            > your browser.
            >
            > To unsubscribe from these emails, visit your user preferences
            > <https://meta.discourse.org/my/preferences>.
            >

            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
            the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown
            fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.
            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
            the lazy dog. The quick brown fox jumps over the lazy dog.
          BODY
        )
    end

    it "properly renders email reply from gmail web client" do
      expect(test_parse_body(fixture_file("emails/gmail_web.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### This is a reply from standard GMail in Google Chrome.

            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
            the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown
            fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.
            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
            the lazy dog. The quick brown fox jumps over the lazy dog.

            Here's some **bold** text in Markdown.

            Here's a link http://example.com
          BODY
        )
    end

    context 'properly renders email reply from gmail web client', feature_category: :service_desk do
      it do
        expect(test_parse_body(fixture_file("emails/html_only.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### This is a reply from standard GMail in Google Chrome.

            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.

            Here's some **bold** text, **strong** text and *italic* in Markdown.

            Here's a link http://example.com

            Here's an img ![Miro](http://img.png)<details>
            <summary>
            One</summary>
            Some details</details>

            <details>
            <summary>
            Two</summary>
            Some details</details>

            Test reply.

            First paragraph.

            Second paragraph.
          BODY
        )
      end
    end

    it "properly renders email reply from iOS default mail client" do
      expect(test_parse_body(fixture_file("emails/ios_default.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### this is a reply from iOS default mail

            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.

            Here's some **bold** markdown text.

            Here's a link http://example.com
          BODY
        )
    end

    it "properly renders email reply from Android 5 gmail client" do
      expect(test_parse_body(fixture_file("emails/android_gmail.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### this is a reply from Android 5 gmail

            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
            the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown
            fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.
            The quick brown fox jumps over the lazy dog.

            This is **bold** in Markdown.

            This is a link to http://example.com
          BODY
        )
    end

    it "properly renders email reply from Windows 8.1 Metro default mail client" do
      expect(test_parse_body(fixture_file("emails/windows_8_metro.eml")))
        .to eq(
          <<-BODY.strip_heredoc.chomp
            ### reply from default mail client in Windows 8.1 Metro


            The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.


            This is a **bold** word in Markdown


            This is a link http://example.com
          BODY
        )
    end

    it "properly renders email reply from MS Outlook client" do
      expect(test_parse_body(fixture_file("emails/outlook.eml"))).to eq("Microsoft Outlook 2010")
    end

    it "properly renders html-only email from MS Outlook" do
      expect(test_parse_body(fixture_file("emails/outlook_html.eml"))).to eq("Microsoft Outlook 2010")
    end

    it "does not wrap links with no href in unnecessary brackets" do
      expect(test_parse_body(fixture_file("emails/html_empty_link.eml"))).to eq("no brackets!")
    end

    it "does not trim reply if trim_reply option is false" do
      expect(test_parse_body(fixture_file("emails/valid_new_issue_with_quote.eml"), { trim_reply: false }))
        .to eq(
          <<-BODY.strip_heredoc.chomp
          The reply by email functionality should be extended to allow creating a new issue by email.
          even when the email is forwarded to the project which may include lines that begin with ">"

          there should be a quote below this line:

          > this is a quote
          BODY
        )
    end

    it "appends trimmed reply when when append_reply option is true" do
      body = <<-BODY.strip_heredoc.chomp
      The reply by email functionality should be extended to allow creating a new issue by email.
      even when the email is forwarded to the project which may include lines that begin with ">"

      there should be a quote below this line:
      BODY

      reply = <<-BODY.strip_heredoc.chomp
      > this is a quote
      BODY

      expect(test_parse_body(fixture_file("emails/valid_new_issue_with_quote.eml"), { append_reply: true }))
        .to contain_exactly(body, reply)
    end

    context 'non-UTF-8 content' do
      let(:charset) { '; charset=Shift_JIS' }
      let(:raw_content) do
        <<-BODY.strip_heredoc.chomp
          From: Jake the Dog <alan@adventuretime.ooo>
          To: incoming+email-test-project_id-issue-@appmail.adventuretime.ooo
          Message-ID: <CAH_Wr+rNGAGGbV2iE5p918UVy4UyJqVcXRO2=otppgzduJSg@mail.gmail.com>
          Subject: The message subject! @all
          Content-Type: text/plain#{charset}
          Content-Transfer-Encoding: 8bit

          こんにちは。 この世界は素晴らしいです。
        BODY
      end

      # Strip encoding to simulate the case when Ruby fallback to ASCII-8bit
      # when it meets an unknown encoding
      let(:encoded_content) { raw_content.encode("Shift_JIS").bytes.pack("c*") }

      it "parses body under UTF-8 encoding" do
        expect(test_parse_body(encoded_content))
          .to eq(<<-BODY.strip_heredoc.chomp)
            こんにちは。 この世界は素晴らしいです。
          BODY
      end

      # This test would raise an exception if encoding is not handled properly
      # Issue: https://gitlab.com/gitlab-org/gitlab/-/issues/364329
      context 'charset is absent and reply trimming is disabled' do
        let(:charset) { '' }

        it "parses body under UTF-8 encoding" do
          expect(test_parse_body(encoded_content, { trim_reply: false }))
            .to eq(<<-BODY.strip_heredoc.chomp)
              こんにちは。 この世界は素晴らしいです。
            BODY
        end
      end

      context 'multipart email' do
        let(:raw_content) do
          <<-BODY.strip_heredoc.chomp
            From: Jake the Dog <alan@adventuretime.ooo>
            To: incoming+email-test-project_id-issue-@appmail.adventuretime.ooo
            Message-ID: <CAH_Wr+rNGAGGbV2iE5p918UVy4UyJqVcXRO2=otppgzduJSg@mail.gmail.com>
            Subject: The message subject! @all
            Content-Type: multipart/alternative;
              boundary=Apple-Mail-B41C7F8E-3639-49B0-A5D5-440E125A7105
            Content-Transfer-Encoding: 7bbit

            --Apple-Mail-B41C7F8E-3639-49B0-A5D5-440E125A7105
            Content-Type: text/plain
            Content-Transfer-Encodng: 7bit

            こんにちは。 この世界は素晴らしいです。
          BODY
        end

        it "parses body under UTF-8 encoding" do
          expect(test_parse_body(encoded_content, { trim_reply: false }))
            .to eq(<<-BODY.strip_heredoc.chomp)
              こんにちは。 この世界は素晴らしいです。
            BODY
        end
      end
    end

    context 'iso-8859-2 content' do
      let(:raw_content) do
        <<-BODY.strip_heredoc.chomp
          From: Jake the Dog <jake@adventuretime.ooo>
          To: <incoming+email-test-project_id-issue-@appmail.adventuretime.ooo>
          Subject: =?iso-8859-2?B?VGVzdGluZyBlbmNvZGluZyBpc28tODg1OS0yILu+uei1vru76A==?=
          Date: Wed, 31 May 2023 18:43:32 +0200
          Message-ID: <CADkmRc+rNGAGGbV2iE5p918UVy4UyJqVcXRO2=otppgzduJSg@mail.gmail.com>
          MIME-Version: 1.0
          Content-Type: multipart/alternative;
                  boundary="----=_NextPart_000_0001_01D993EF.CDD81EA0"
          X-Mailer: Microsoft Outlook 16.0
          Thread-Index: AdmT3ur1lfLfsfGgRM699GyWkjowfg==
          Content-Language: en-us

          This is a multipart message in MIME format.

          ------=_NextPart_000_0001_01D993EF.CDD81EA0
          Content-Type: text/plain;
                  charset="iso-8859-2"
          Content-Transfer-Encoding: base64

          Qm9keSBvZiBlbmNvZGluZyBpc28tODg1OS0yIHRlc3Q6ILu+uei1vru76A0KDQo=
        BODY
      end

      it "parses body under UTF-8 encoding" do
        expect(test_parse_body(raw_content, { trim_reply: false }))
          .to eq(<<-BODY.strip_heredoc.chomp)
            Body of encoding iso-8859-2 test: ťžščľžťťč\r\n\r\n
          BODY
      end
    end
  end
end
