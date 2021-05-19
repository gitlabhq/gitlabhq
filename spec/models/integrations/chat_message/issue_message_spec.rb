# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::IssueMessage do
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
        title: 'Issue title',
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
        action: 'open',
        state: 'opened',
        description: 'issue description'
      }
    }
  end

  context 'without markdown' do
    let(:color) { '#C95823' }

    describe '#initialize' do
      before do
        args[:object_attributes][:description] = nil
      end

      it 'returns a non-null description' do
        expect(subject.description).to eq('')
      end
    end

    context 'open' do
      it 'returns a message regarding opening of issues' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Issue title> opened by Test User (test.user)')
        expect(subject.attachments).to eq([
          {
            title: "#100 Issue title",
            title_link: "http://url.com",
            text: "issue description",
            color: color
          }
        ])
      end
    end

    context 'close' do
      before do
        args[:object_attributes][:action] = 'close'
        args[:object_attributes][:state] = 'closed'
      end

      it 'returns a message regarding closing of issues' do
        expect(subject.pretext). to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Issue title> closed by Test User (test.user)')
        expect(subject.attachments).to be_empty
      end
    end

    context 'reopen' do
      before do
        args[:object_attributes][:action] = 'reopen'
        args[:object_attributes][:state] = 'opened'
      end

      it 'returns a message regarding reopening of issues' do
        expect(subject.pretext)
          .to eq('[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Issue title> opened by Test User (test.user)')
        expect(subject.attachments).to be_empty
      end
    end
  end

  context 'with markdown' do
    before do
      args[:markdown] = true
    end

    context 'open' do
      it 'returns a message regarding opening of issues' do
        expect(subject.pretext).to eq(
          '[[project_name](http://somewhere.com)] Issue [#100 Issue title](http://url.com) opened by Test User (test.user)')
        expect(subject.attachments).to eq('issue description')
        expect(subject.activity).to eq({
          title: 'Issue opened by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[#100 Issue title](http://url.com)',
          image: 'http://someavatar.com'
        })
      end
    end

    context 'close' do
      before do
        args[:object_attributes][:action] = 'close'
        args[:object_attributes][:state] = 'closed'
      end

      it 'returns a message regarding closing of issues' do
        expect(subject.pretext). to eq(
          '[[project_name](http://somewhere.com)] Issue [#100 Issue title](http://url.com) closed by Test User (test.user)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Issue closed by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[#100 Issue title](http://url.com)',
          image: 'http://someavatar.com'
        })
      end
    end
  end
end
