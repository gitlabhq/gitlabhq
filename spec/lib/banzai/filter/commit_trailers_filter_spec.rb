# frozen_string_literal: true

require 'spec_helper'
require 'ffaker'

RSpec.describe Banzai::Filter::CommitTrailersFilter, feature_category: :source_code_management do
  include FilterSpecHelper
  include CommitTrailersSpecHelper

  let(:secondary_email)     { create(:email, :confirmed) }
  let(:user)                { create(:user, :public_email) }
  let(:email)               { FFaker::Internet.email }

  let(:trailer)             { "#{generate(:short_text)}-by:" }

  let(:commit_message)      { trailer_line(trailer, user.name, user.public_email) }
  let(:commit_message_html) { commit_html(commit_message) }

  context 'detects' do
    context 'trailers in the form of *-by' do
      where(:commit_trailer) do
        ["#{FFaker::Lorem.word}-by:", "#{FFaker::Lorem.word}-BY:", "#{FFaker::Lorem.word}-By:"]
      end

      with_them do
        let(:trailer) { commit_trailer }

        it 'replaces users with links' do
          doc = filter(commit_message_html)

          expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
        end
      end
    end

    it 'trailers prefixed with whitespaces' do
      message_html = commit_html("\n\r  #{commit_message}")

      doc = filter(message_html)

      expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
    end

    context 'with leading whitespace' do
      let(:trailer) { "\t\t\t#{generate(:short_text)}-by:" }

      it 'preserves whitespace' do
        doc = filter(commit_message_html)

        expect(doc.to_html).to include("\t\t\t")
        expect(doc.to_html).to include(trailer.strip)
      end
    end

    context 'with mixed whitespace' do
      let(:trailer) { "  \t  #{generate(:short_text)}-by:" }

      it 'preserves whitespace' do
        doc = filter(commit_message_html)

        expect(doc.to_html).to include("  \t  ")
        expect(doc.to_html).to include(trailer.strip)
      end
    end

    it 'does not detect GitLab users via a secondary email' do
      _, message_html = build_commit_message(
        trailer: trailer,
        name: secondary_email.user.name,
        email: secondary_email.email
      )

      doc = filter(message_html)

      expect_to_have_mailto_link_with_avatar(
        doc,
        trailer: trailer,
        email: secondary_email.email
      )
    end

    context 'non GitLab users' do
      shared_examples 'mailto links' do
        it 'replaces them with mailto links' do
          _, message_html = build_commit_message(
            trailer: trailer,
            name: FFaker::Name.name,
            email: email
          )

          doc = filter(message_html)

          expect_to_have_mailto_link_with_avatar(doc, email: email, trailer: trailer)
        end
      end

      context 'when Gravatar is disabled' do
        before do
          stub_application_setting(gravatar_enabled: false)
        end

        it_behaves_like 'mailto links'
      end

      context 'when Gravatar is enabled' do
        before do
          stub_application_setting(gravatar_enabled: true)
        end

        it_behaves_like 'mailto links'
      end
    end

    it 'multiple trailers in the same message' do
      different_trailer = "#{generate(:short_text)}-by:"
      message = commit_html %(
        #{commit_message}
        #{trailer_line(different_trailer, FFaker::Name.name, email)}
      )

      doc = filter(message)

      expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
      expect_to_have_mailto_link_with_avatar(doc, email: email, trailer: different_trailer)
    end

    context 'special names' do
      where(:name) do
        [
          'John S. Doe',
          'L33t H@x0r'
        ]
      end

      with_them do
        it do
          message, message_html = build_commit_message(
            trailer: trailer,
            name: name,
            email: email
          )

          doc = filter(message_html)

          expect_to_have_mailto_link_with_avatar(doc, email: email, trailer: trailer)
          expect(doc.text).to match Regexp.escape(message)
        end
      end
    end
  end

  context "ignores" do
    it 'commit messages without trailers' do
      exp = message = commit_html(Array.new(5) { FFaker::Lorem.sentence }.join("\n"))
      doc = filter(message)

      expect(doc.to_html).to match Regexp.escape(exp)
    end

    it 'trailers without emails' do
      exp = message = commit_html(Array.new(5) { 'Merged-By:' }.join("\n"))
      doc = filter(message)

      expect(doc.to_html).to match Regexp.escape(exp)
    end

    it 'trailers that are inline the commit message body' do
      message = commit_html %(
        #{FFaker::Lorem.sentence} #{commit_message} #{FFaker::Lorem.sentence}
      )

      doc = filter(message)

      expect(doc.css('a').size).to eq 0
    end
  end

  context "structure" do
    it 'starts with two newlines to separate with actual commit message' do
      doc = filter(commit_message_html)

      expect(doc.xpath('pre').text).to start_with("\n\n")
    end

    it 'preserves the commit trailer structure' do
      doc = filter(commit_message_html)

      expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
      expect(doc.text).to match Regexp.escape(commit_message)
    end

    it 'preserves the original name used in the commit message' do
      message, message_html = build_commit_message(
        trailer: trailer,
        name: FFaker::Name.name,
        email: user.email
      )

      doc = filter(message_html)

      expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
      expect(doc.text).to match Regexp.escape(message)
    end

    it 'preserves the original email used in the commit message' do
      message, message_html = build_commit_message(
        trailer: trailer,
        name: user.name,
        email: email
      )

      doc = filter(message_html)

      expect_to_have_mailto_link_with_avatar(
        doc,
        trailer: trailer,
        email: email
      )
      expect(doc.text).to match Regexp.escape(message)
    end

    it 'only replaces trailer lines not the full commit message' do
      commit_body = FFaker::Lorem.paragraph
      message = commit_html %(
        #{commit_body}
        #{commit_message}
      )

      doc = filter(message)

      expect_to_have_user_link_with_avatar(doc, user: user, trailer: trailer)
      expect(doc.text).to include(commit_body)
    end

    context 'with Gitlab-hosted avatars in commit trailers' do
      # Because commit trailers are contained within markdown,
      # any path-only link will automatically be prefixed
      # with the path of its repository.
      # See: "build_relative_path" in "lib/banzai/filter/relative_link_filter.rb"
      let(:user_with_avatar) { create(:user, :public_email, :with_avatar, username: 'foobar') }

      it 'returns a full path for avatar urls' do
        _, message_html = build_commit_message(
          trailer: trailer,
          name: user_with_avatar.name,
          email: user_with_avatar.email
        )

        doc = filter(message_html)
        expected = "#{Gitlab.config.gitlab.url}#{user_with_avatar.avatar_url}"

        expect(doc.css('img')[0].attr('src')).to start_with expected
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
