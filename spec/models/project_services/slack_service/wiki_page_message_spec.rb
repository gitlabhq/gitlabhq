require 'spec_helper'

describe SlackService::WikiPageMessage, models: true do
  subject { SlackService::WikiPageMessage.new(args) }

  let(:args) do
    {
      user: {
        name: 'Test User',
        username: 'Test User'
      },
      project_name: 'project_name',
      project_url: 'somewhere.com',
      object_attributes: {
        title: 'Wiki page title',
        url: 'url',
        content: 'Wiki page description'
      }
    }
  end

  let(:color) { '#345' }

  describe '#pretext' do
    context 'when :action == "create"' do
      before { args[:object_attributes][:action] = 'create' }

      it do
        expect(subject.pretext).to eq(
          'Test User created <url|wiki page> in <somewhere.com|project_name>: '\
          '*Wiki page title*')
      end
    end

    context 'when :action == "update"' do
      before { args[:object_attributes][:action] = 'update' }

      it do
        expect(subject.pretext).to eq(
          'Test User edited <url|wiki page> in <somewhere.com|project_name>: '\
          '*Wiki page title*')
      end
    end
  end

  describe '#attachments' do
    context 'when :action == "create"' do
      before { args[:object_attributes][:action] = 'create' }

      it do
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

      it do
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
