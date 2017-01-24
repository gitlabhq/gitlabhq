require 'spec_helper'

describe ChatMessage::WikiPageMessage, models: true do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
        name: 'Test User',
        username: 'test.user'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',
      object_attributes: {
        title: 'Wiki page title',
        url: 'http://url.com',
        content: 'Wiki page description'
      }
    }
  end

  describe '#pretext' do
    context 'when :action == "create"' do
      before { args[:object_attributes][:action] = 'create' }

      it 'returns a message that a new wiki page was created' do
        expect(subject.pretext).to eq(
          'test.user created <http://url.com|wiki page> in <http://somewhere.com|project_name>: '\
          '*Wiki page title*')
      end
    end

    context 'when :action == "update"' do
      before { args[:object_attributes][:action] = 'update' }

      it 'returns a message that a wiki page was updated' do
        expect(subject.pretext).to eq(
          'test.user edited <http://url.com|wiki page> in <http://somewhere.com|project_name>: '\
          '*Wiki page title*')
      end
    end
  end

  describe '#attachments' do
    let(:color) { '#345' }

    context 'when :action == "create"' do
      before { args[:object_attributes][:action] = 'create' }

      it 'returns the attachment for a new wiki page' do
        expect(subject.attachments).to eq([
          {
            text: "Wiki page description",
            color: color,
          }
        ])
      end
    end

    context 'when :action == "update"' do
      before { args[:object_attributes][:action] = 'update' }

      it 'returns the attachment for an updated wiki page' do
        expect(subject.attachments).to eq([
          {
            text: "Wiki page description",
            color: color,
          }
        ])
      end
    end
  end
end
