require "spec_helper"

# Inspired in great part by Discourse's Email::Receiver
describe Gitlab::Email::ReplyParser do
  def fixture_file(filename)
    return '' if filename.blank?
    file_path = File.expand_path(Rails.root + 'spec/fixtures/' + filename)
    File.read(file_path)
  end

  describe 'self.parse_body' do
    def test_parse_body(mail_string)
      described_class.new(Mail::Message.new(mail_string)).execute
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

    it "can parse the html section" do
      expect(test_parse_body(fixture_file("emails/html_only.eml"))).to eq("The EC2 instance - I've seen that there tends to be odd and " +
          "unrecommended settings on the Bitnami installs that I've checked out.")
    end

    it "supports a Dutch reply" do
      expect(test_parse_body(fixture_file("emails/dutch.eml"))).to eq("Dit is een antwoord in het Nederlands.")
    end

    it "removes an 'on date wrote' quoting line" do
      expect(test_parse_body(fixture_file("emails/on_wrote.eml"))).to eq("Sure, all you need to do is frobnicate the foobar and you'll be all set!")
    end

    it "handles multiple paragraphs" do
      expect(test_parse_body(fixture_file("emails/paragraphs.eml"))).
          to eq(
"Is there any reason the *old* candy can't be be kept in silos while the new candy
is imported into *new* silos?

The thing about candy is it stays delicious for a long time -- we can just keep
it there without worrying about it too much, imo.

Thanks for listening."
      )
    end

    it "handles multiple paragraphs when parsing html" do
      expect(test_parse_body(fixture_file("emails/html_paragraphs.eml"))).
          to eq(
"Awesome!

Pleasure to have you here!

:boom:"
      )
    end

    it "handles newlines" do
      expect(test_parse_body(fixture_file("emails/newlines.eml"))).
          to eq(
"This is my reply.
It is my best reply.
It will also be my *only* reply."
      )
    end

    it "handles inline reply" do
      expect(test_parse_body(fixture_file("emails/inline_reply.eml"))).
          to eq(
"On Wed, Oct 8, 2014 at 11:12 AM, techAPJ <info@unconfigured.discourse.org> wrote:

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
the lazy dog. The quick brown fox jumps over the lazy dog."
      )
    end

    it "strips iPhone signature" do
      expect(test_parse_body(fixture_file("emails/iphone_signature.eml"))).not_to match /Sent from my iPhone/
    end

    it "properly renders email reply from gmail web client" do
      expect(test_parse_body(fixture_file("emails/gmail_web.eml"))).
          to eq(
"### This is a reply from standard GMail in Google Chrome.

The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown
fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.
The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
the lazy dog. The quick brown fox jumps over the lazy dog.

Here's some **bold** text in Markdown.

Here's a link http://example.com"
      )
    end

    it "properly renders email reply from iOS default mail client" do
      expect(test_parse_body(fixture_file("emails/ios_default.eml"))).
          to eq(
"### this is a reply from iOS default mail

The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.

Here's some **bold** markdown text.

Here's a link http://example.com"
      )
    end

    it "properly renders email reply from Android 5 gmail client" do
      expect(test_parse_body(fixture_file("emails/android_gmail.eml"))).
          to eq(
"### this is a reply from Android 5 gmail

The quick brown fox jumps over the lazy dog. The quick brown fox jumps over
the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown
fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.
The quick brown fox jumps over the lazy dog.

This is **bold** in Markdown.

This is a link to http://example.com"
      )
    end

    it "properly renders email reply from Windows 8.1 Metro default mail client" do
      expect(test_parse_body(fixture_file("emails/windows_8_metro.eml"))).
          to eq(
"### reply from default mail client in Windows 8.1 Metro


The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog.


This is a **bold** word in Markdown


This is a link http://example.com"
      )
    end

    it "properly renders email reply from MS Outlook client" do
      expect(test_parse_body(fixture_file("emails/outlook.eml"))).to eq("Microsoft Outlook 2010")
    end
  end
end
