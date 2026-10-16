# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::PushMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      after: 'after',
      before: 'before',
      project_name: 'project_name',
      ref: 'refs/heads/master',
      user_name: 'test.user',
      user_avatar: 'http://someavatar.com',
      project_url: 'http://url.com'
    }
  end

  let(:color) { '#334455' }

  it_behaves_like Integrations::ChatMessage

  context 'with HTML formatting', feature_category: :integrations do
    subject(:message) { described_class.new(args) }

    let(:args) do
      super().merge(
        html: true, before: '1' * 40, after: '2' * 40,
        ref: 'refs/heads/topic_<example>&tools', user_name: 'example_bot',
        project_name: 'Project_<example> & tools', project_url: 'https://gitlab.example.com/group/project'
      )
    end

    it 'escapes a linked branch name and preserves the compare link' do
      expect(message.summary).to eq(
        'example_bot pushed to branch ' \
          '<a href="https://gitlab.example.com/group/project/-/commits/topic_&lt;example&gt;&amp;tools">' \
          'topic_&lt;example&gt;&amp;tools</a> of ' \
          '<a href="https://gitlab.example.com/group/project">Project_&lt;example&gt; &amp; tools</a> ' \
          '(<a href="https://gitlab.example.com/group/project/-/compare/' \
          "#{'1' * 40}...#{'2' * 40}\">Compare changes</a>)"
      )
    end

    context 'when a branch is removed' do
      let(:args) { super().merge(after: '0' * 40) }

      it 'escapes the branch name when it has no link' do
        expect(message.summary).to eq(
          'example_bot removed branch topic_&lt;example&gt;&amp;tools from ' \
            '<a href="https://gitlab.example.com/group/project">Project_&lt;example&gt; &amp; tools</a>'
        )
      end
    end
  end

  context 'push' do
    before do
      args[:commits] = [
        { message: 'message1', title: 'message1', url: 'http://url1.com', id: 'abcdefghijkl', author: { name: 'author1' } },
        {
          message: 'message2' + (' w' * 100) + "\nsecondline",
          title: 'message2 w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w ...',
          url: 'http://url2.com',
          id: '123456789012',
          author: { name: 'author2' }
        }
      ]
    end

    context 'without markdown' do
      it 'returns a message regarding pushes' do
        expect(subject.pretext).to eq(
          'test.user pushed to branch <http://url.com/-/commits/master|master> of '\
            '<http://url.com|project_name> (<http://url.com/-/compare/before...after|Compare changes>)')
        expect(subject.attachments).to eq([{
          text: "<http://url1.com|abcdefgh>: message1 - author1\n\n"\
            "<http://url2.com|12345678>: message2 w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w ... - author2",
          color: color
        }])
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding pushes' do
        expect(subject.pretext).to eq(
          'test.user pushed to branch [master](http://url.com/-/commits/master) of [project_name](http://url.com) ([Compare changes](http://url.com/-/compare/before...after))')
        expect(subject.attachments).to eq(
          "[abcdefgh](http://url1.com): message1 - author1\n\n[12345678](http://url2.com): message2 w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w w ... - author2")
        expect(subject.activity).to eq(
          title: 'test.user pushed to branch [master](http://url.com/-/commits/master)',
          subtitle: 'in [project_name](http://url.com)',
          text: '[Compare changes](http://url.com/-/compare/before...after)',
          image: 'http://someavatar.com'
        )
      end
    end
  end

  context 'tag push' do
    let(:args) do
      {
        after: 'after',
        before: Gitlab::Git::SHA1_BLANK_SHA,
        project_name: 'project_name',
        ref: 'refs/tags/new_tag',
        user_name: 'test.user',
        user_avatar: 'http://someavatar.com',
        project_url: 'http://url.com'
      }
    end

    context 'without markdown' do
      it 'returns a message regarding pushes' do
        expect(subject.pretext).to eq('test.user pushed new tag ' \
          '<http://url.com/-/tags/new_tag|new_tag> to ' \
          '<http://url.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding pushes' do
        expect(subject.pretext).to eq(
          'test.user pushed new tag [new_tag](http://url.com/-/tags/new_tag) to [project_name](http://url.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq(
          title: 'test.user pushed new tag [new_tag](http://url.com/-/tags/new_tag)',
          subtitle: 'in [project_name](http://url.com)',
          text: '[Compare changes](http://url.com/-/compare/0000000000000000000000000000000000000000...after)',
          image: 'http://someavatar.com'
        )
      end
    end
  end

  context 'removed tag' do
    let(:args) do
      {
        after: Gitlab::Git::SHA1_BLANK_SHA,
        before: 'before',
        project_name: 'project_name',
        ref: 'refs/tags/new_tag',
        user_name: 'test.user',
        user_avatar: 'http://someavatar.com',
        project_url: 'http://url.com'
      }
    end

    context 'without markdown' do
      it 'returns a message regarding removal of tags' do
        expect(subject.pretext).to eq('test.user removed tag ' \
          'new_tag from ' \
          '<http://url.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding removal of tags' do
        expect(subject.pretext).to eq(
          'test.user removed tag new_tag from [project_name](http://url.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq(
          title: 'test.user removed tag new_tag',
          subtitle: 'in [project_name](http://url.com)',
          text: '[Compare changes](http://url.com/-/compare/before...0000000000000000000000000000000000000000)',
          image: 'http://someavatar.com'
        )
      end
    end
  end

  context 'new branch' do
    before do
      args[:before] = Gitlab::Git::SHA1_BLANK_SHA
    end

    context 'without markdown' do
      it 'returns a message regarding a new branch' do
        expect(subject.pretext).to eq(
          'test.user pushed new branch <http://url.com/-/commits/master|master> to '\
            '<http://url.com|project_name>')
        expect(subject.attachments).to be_empty
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding a new branch' do
        expect(subject.pretext).to eq(
          'test.user pushed new branch [master](http://url.com/-/commits/master) to [project_name](http://url.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq(
          title: 'test.user pushed new branch [master](http://url.com/-/commits/master)',
          subtitle: 'in [project_name](http://url.com)',
          text: '[Compare changes](http://url.com/-/compare/0000000000000000000000000000000000000000...after)',
          image: 'http://someavatar.com'
        )
      end
    end
  end

  context 'removed branch' do
    before do
      args[:after] = Gitlab::Git::SHA1_BLANK_SHA
    end

    context 'when the branch name contains markup', feature_category: :integrations do
      using RSpec::Parameterized::TableSyntax

      let(:args) { super().merge(ref: 'refs/heads/topic_<example>&tools', markdown: markdown) }

      where(:markdown, :project_link) do
        true  | '[project_name](http://url.com)'
        false | '<http://url.com|project_name>'
      end

      with_them do
        it 'preserves the unlinked branch name' do
          expect(subject.pretext).to eq("test.user removed branch topic_<example>&tools from #{project_link}")
        end
      end
    end

    context 'without markdown' do
      it 'returns a message regarding a removed branch' do
        expect(subject.pretext).to eq(
          'test.user removed branch master from <http://url.com|project_name>')
        expect(subject.attachments).to be_empty
      end

      context 'when the branch name contains an HTML link' do
        before do
          args[:ref] = 'refs/heads/<a href="https://evil.example.com">https://gitlab.example.com/branch</a>'
        end

        it 'does not convert the HTML link into a Slack link' do
          expect(subject.pretext).to eq(
            'test.user removed branch <a href="https://evil.example.com">https://gitlab.example.com/branch</a> ' \
              'from <http://url.com|project_name>')
        end
      end
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns a message regarding a removed branch' do
        expect(subject.pretext).to eq(
          'test.user removed branch master from [project_name](http://url.com)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq(
          title: 'test.user removed branch master',
          subtitle: 'in [project_name](http://url.com)',
          text: '[Compare changes](http://url.com/-/compare/before...0000000000000000000000000000000000000000)',
          image: 'http://someavatar.com'
        )
      end
    end
  end

  describe '#attachment_color' do
    it 'returns the correct color' do
      expect(subject.attachment_color).to eq('#334455')
    end
  end
end
