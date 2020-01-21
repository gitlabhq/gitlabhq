# frozen_string_literal: true

require 'spec_helper'

describe ChatMessage::WikiPageMessage do
  subject { described_class.new(args) }

  let(:args) do
    {
      user: {
        name: 'Test User',
        username: 'test.user',
        avatar_url: 'http://someavatar.com'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',
      object_attributes: {
        title: 'Wiki page title',
        url: 'http://url.com',
        content: 'Wiki page content',
        message: 'Wiki page commit message'
      }
    }
  end

  context 'without markdown' do
    describe '#pretext' do
      context 'when :action == "create"' do
        before do
          args[:object_attributes][:action] = 'create'
        end

        it 'returns a message that a new wiki page was created' do
          expect(subject.pretext).to eq(
            'Test User (test.user) created <http://url.com|wiki page> in <http://somewhere.com|project_name>: '\
              '*Wiki page title*')
        end
      end

      context 'when :action == "update"' do
        before do
          args[:object_attributes][:action] = 'update'
        end

        it 'returns a message that a wiki page was updated' do
          expect(subject.pretext).to eq(
            'Test User (test.user) edited <http://url.com|wiki page> in <http://somewhere.com|project_name>: '\
              '*Wiki page title*')
        end
      end
    end

    describe '#attachments' do
      let(:color) { '#345' }

      context 'when :action == "create"' do
        before do
          args[:object_attributes][:action] = 'create'
        end

        it 'returns the commit message for a new wiki page' do
          expect(subject.attachments).to eq([
            {
              text: "Wiki page commit message",
              color: color
            }
          ])
        end
      end

      context 'when :action == "update"' do
        before do
          args[:object_attributes][:action] = 'update'
        end

        it 'returns the commit message for an updated wiki page' do
          expect(subject.attachments).to eq([
            {
              text: "Wiki page commit message",
              color: color
            }
          ])
        end
      end
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    describe '#pretext' do
      context 'when :action == "create"' do
        before do
          args[:object_attributes][:action] = 'create'
        end

        it 'returns a message that a new wiki page was created' do
          expect(subject.pretext).to eq(
            'Test User (test.user) created [wiki page](http://url.com) in [project_name](http://somewhere.com): *Wiki page title*')
        end
      end

      context 'when :action == "update"' do
        before do
          args[:object_attributes][:action] = 'update'
        end

        it 'returns a message that a wiki page was updated' do
          expect(subject.pretext).to eq(
            'Test User (test.user) edited [wiki page](http://url.com) in [project_name](http://somewhere.com): *Wiki page title*')
        end
      end
    end

    describe '#attachments' do
      context 'when :action == "create"' do
        before do
          args[:object_attributes][:action] = 'create'
        end

        it 'returns the commit message for a new wiki page' do
          expect(subject.attachments).to eq('Wiki page commit message')
        end
      end

      context 'when :action == "update"' do
        before do
          args[:object_attributes][:action] = 'update'
        end

        it 'returns the commit message for an updated wiki page' do
          expect(subject.attachments).to eq('Wiki page commit message')
        end
      end
    end

    describe '#activity' do
      context 'when :action == "create"' do
        before do
          args[:object_attributes][:action] = 'create'
        end

        it 'returns the attachment for a new wiki page' do
          expect(subject.activity).to eq({
            title: 'Test User (test.user) created [wiki page](http://url.com)',
            subtitle: 'in [project_name](http://somewhere.com)',
            text: 'Wiki page title',
            image: 'http://someavatar.com'
          })
        end
      end

      context 'when :action == "update"' do
        before do
          args[:object_attributes][:action] = 'update'
        end

        it 'returns the attachment for an updated wiki page' do
          expect(subject.activity).to eq({
            title: 'Test User (test.user) edited [wiki page](http://url.com)',
            subtitle: 'in [project_name](http://somewhere.com)',
            text: 'Wiki page title',
            image: 'http://someavatar.com'
          })
        end
      end
    end
  end
end
