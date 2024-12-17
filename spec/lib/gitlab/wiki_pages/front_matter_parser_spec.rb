# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WikiPages::FrontMatterParser, feature_category: :wiki do
  subject(:parser) { described_class.new(raw_content) }

  let(:content) { 'This is the content' }
  let(:end_divider) { '---' }

  let(:with_front_matter) do
    <<~MD
    ---
    a: 1
    b: 2
    c:
     - foo
     - bar
    date: I am safe. Not actually a date
    #{end_divider}
    #{content}
    MD
  end

  def have_correct_front_matter
    include(a: 1, b: 2, c: %w[foo bar])
  end

  describe '#parse' do
    subject { parser.parse }

    context 'there is front matter' do
      let(:raw_content) { with_front_matter }

      it do
        is_expected.to have_attributes(
          front_matter: have_correct_front_matter,
          content: content + "\n",
          error: be_nil
        )
      end
    end

    context 'there is no content' do
      let(:raw_content) { '' }

      it do
        is_expected.to have_attributes(
          front_matter: {},
          content: raw_content,
          error: be_nil
        )
      end
    end

    context 'there is no front_matter' do
      let(:raw_content) { content }

      it { is_expected.to have_attributes(front_matter: be_empty, content: raw_content) }

      it { is_expected.to have_attributes(reason: :no_match) }
    end

    context 'default' do
      let(:raw_content) { with_front_matter }

      it do
        is_expected.to have_attributes(
          front_matter: have_correct_front_matter,
          content: content + "\n",
          reason: be_nil
        )
      end
    end

    context 'the end divider is ...' do
      let(:end_divider) { '...' }
      let(:raw_content) { with_front_matter }

      it { is_expected.to have_attributes(front_matter: have_correct_front_matter) }
    end

    context 'the front-matter is not a mapping' do
      let(:raw_content) do
        <<~MD
        ---
        - thing one
        - thing two
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :not_mapping) }
    end

    context 'there is nothing in the front-matter block' do
      let(:raw_content) do
        <<~MD
        ---
        ---
        My content here
        MD
      end

      it { is_expected.to have_attributes(reason: :no_match) }
    end

    context 'there is a string in the YAML block' do
      let(:raw_content) do
        <<~MD
        ---
        This is a string
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :not_mapping) }
    end

    context 'there is dangerous YAML in the block' do
      let(:raw_content) do
        <<~MD
        ---
        date: 2010-02-11 11:02:57
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :parse_error, error: be_present) }
    end

    context 'there is acceptably long YAML in the front-matter block' do
      let(:raw_content) do
        key = 'title: '
        length = described_class::MAX_FRONT_MATTER_LENGTH - key.size

        <<~MD
        ---
        title: #{FFaker::Lorem.characters(length)}
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(front_matter: include(title: be_present)) }
    end

    context 'there is suspiciously long YAML in the front-matter block' do
      let(:raw_content) do
        <<~MD
        ---
        title: #{FFaker::Lorem.characters(described_class::MAX_FRONT_MATTER_LENGTH)}
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :too_long) }
    end

    context 'TOML front matter' do
      let(:raw_content) do
        <<~MD
        +++
        title = "My title"
        +++
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :not_yaml) }
    end

    context 'TOML style fences, advertised as YAML' do
      let(:raw_content) do
        <<~MD
        +++ yaml
        title: "My title"
        +++
        #{content}
        MD
      end

      it { is_expected.to have_attributes(front_matter: include(title: 'My title')) }
    end

    context 'YAML, advertised as something else' do
      let(:raw_content) do
        <<~MD
        --- toml
        title: My title
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :not_yaml) }
    end

    context 'there is text content in the YAML block, in comments' do
      let(:raw_content) do
        <<~MD
        ---
        # This is YAML
        #
        # It has comments though. Explaining things
        foo: 1

        ## It has headings

        headings:

         - heading one
         - heading two

        # And lists

        lists:

         - and lists
         - with things in them
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(front_matter: include(foo: 1)) }
    end

    context 'there is text content in the YAML block' do
      let(:raw_content) do
        <<~MD
        ---
        # This is not YAML

        In fact is looks like markdown

        ## It has headings

        Paragraphs

        - and lists
        - with things in them
        ---
        #{content}
        MD
      end

      it { is_expected.to have_attributes(reason: :not_mapping) }
    end
  end
end
