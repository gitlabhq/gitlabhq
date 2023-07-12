# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::GroupMentionMessage, feature_category: :integrations do
  subject { described_class.new(args) }

  let(:color) { '#345' }
  let(:args) do
    {
      object_kind: 'group_mention',
      mentioned: {
        object_kind: 'group',
        name: 'test/group',
        url: 'http://test/group'
      },
      user: {
        name: 'Test User',
        username: 'test.user',
        avatar_url: 'http://avatar'
      },
      project_name: 'Test Project',
      project_url: 'http://project'
    }
  end

  context 'for issue descriptions' do
    let(:attachments) { [{ text: "Issue\ndescription\n123", color: color }] }

    before do
      args[:object_attributes] = {
        object_kind: 'issue',
        iid: '42',
        title: 'Test Issue',
        description: "Issue\ndescription\n123",
        url: 'http://issue'
      }
    end

    it 'returns the appropriate message' do
      expect(subject.pretext).to eq(
        'Group <http://test/group|test/group> was mentioned ' \
        'in <http://issue|issue #42> ' \
        'of <http://project|Test Project>: ' \
        '*Test Issue*'
      )
      expect(subject.attachments).to eq(attachments)
    end

    context 'with markdown' do
      before do
        args[:markdown] = true
      end

      it 'returns the appropriate message' do
        expect(subject.pretext).to eq(
          'Group [test/group](http://test/group) was mentioned ' \
          'in [issue #42](http://issue) ' \
          'of [Test Project](http://project): ' \
          '*Test Issue*'
        )
        expect(subject.attachments).to eq("Issue\ndescription\n123")
        expect(subject.activity).to eq(
          {
            title: 'Group [test/group](http://test/group) was mentioned in [issue #42](http://issue)',
            subtitle: 'of [Test Project](http://project)',
            text: 'Test Issue',
            image: 'http://avatar'
          }
        )
      end
    end
  end

  context 'for merge request descriptions' do
    let(:attachments) { [{ text: "MR\ndescription\n123", color: color }] }

    before do
      args[:object_attributes] = {
        object_kind: 'merge_request',
        iid: '42',
        title: 'Test MR',
        description: "MR\ndescription\n123",
        url: 'http://merge_request'
      }
    end

    it 'returns the appropriate message' do
      expect(subject.pretext).to eq(
        'Group <http://test/group|test/group> was mentioned ' \
        'in <http://merge_request|merge request !42> ' \
        'of <http://project|Test Project>: ' \
        '*Test MR*'
      )
      expect(subject.attachments).to eq(attachments)
    end
  end

  context 'for notes' do
    let(:attachments) { [{ text: 'Test Comment', color: color }] }

    before do
      args[:object_attributes] = {
        object_kind: 'note',
        note: 'Test Comment',
        url: 'http://note'
      }
    end

    context 'on commits' do
      before do
        args[:commit] = {
          id: '5f163b2b95e6f53cbd428f5f0b103702a52b9a23',
          title: 'Test Commit',
          message: "Commit\nmessage\n123\n"
        }
      end

      it 'returns the appropriate message' do
        expect(subject.pretext).to eq(
          'Group <http://test/group|test/group> was mentioned ' \
          'in <http://note|commit 5f163b2b> ' \
          'of <http://project|Test Project>: ' \
          '*Test Commit*'
        )
        expect(subject.attachments).to eq(attachments)
      end
    end

    context 'on issues' do
      before do
        args[:issue] = {
          iid: '42',
          title: 'Test Issue'
        }
      end

      it 'returns the appropriate message' do
        expect(subject.pretext).to eq(
          'Group <http://test/group|test/group> was mentioned ' \
          'in <http://note|issue #42> ' \
          'of <http://project|Test Project>: ' \
          '*Test Issue*'
        )
        expect(subject.attachments).to eq(attachments)
      end
    end

    context 'on merge requests' do
      before do
        args[:merge_request] = {
          iid: '42',
          title: 'Test MR'
        }
      end

      it 'returns the appropriate message' do
        expect(subject.pretext).to eq(
          'Group <http://test/group|test/group> was mentioned ' \
          'in <http://note|merge request !42> ' \
          'of <http://project|Test Project>: ' \
          '*Test MR*'
        )
        expect(subject.attachments).to eq(attachments)
      end
    end
  end

  context 'for unsupported object types' do
    before do
      args[:object_attributes] = { object_kind: 'unsupported' }
    end

    it 'raises an error' do
      expect { described_class.new(args) }.to raise_error(NotImplementedError)
    end
  end

  context 'for notes on unsupported object types' do
    before do
      args[:object_attributes] = {
        object_kind: 'note',
        note: 'Test Comment',
        url: 'http://note'
      }
      # Not adding a supported object type's attributes
    end

    it 'raises an error' do
      expect { described_class.new(args) }.to raise_error(NotImplementedError)
    end
  end
end
