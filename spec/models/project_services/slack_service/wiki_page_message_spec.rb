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
        action: 'create',
        content: 'Wiki page description'
      }
    }
  end

  let(:color) { '#345' }

  context 'create' do
    it 'returns a message regarding creation of pages' do
      expect(subject.pretext).to eq(
        'Test User created <url|wiki page> in <somewhere.com|project_name>: '\
        '*Wiki page title*')
      expect(subject.attachments).to eq([
        {
          text: "Wiki page description",
          color: color,
        }
      ])
    end
  end

  context 'update' do
    before do
      args[:object_attributes][:action] = 'update'
    end
    it 'returns a message regarding updating of pages' do
      expect(subject.pretext). to eq(
        'Test User edited <url|wiki page> in <somewhere.com|project_name>: '\
        '*Wiki page title*')
      expect(subject.attachments).to eq([
        {
          text: "Wiki page description",
          color: color,
        }
      ])
    end
  end
end
