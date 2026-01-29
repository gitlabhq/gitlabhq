# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::ChatMessage::IssueMessage, feature_category: :integrations do
  subject { described_class.new(args) }

  let(:args) do
    {
      object_kind: 'issue',
      user: {
        name: 'Test User',
        username: 'test.user',
        avatar_url: 'http://someavatar.com'
      },
      project_name: 'project_name',
      project_url: 'http://somewhere.com',

      object_attributes: {
        title: 'Title',
        id: 10,
        iid: 100,
        assignee_id: 1,
        url: 'http://url.com',
        action: 'open',
        state: 'opened',
        description: 'issue description <http://custom-url.com|CLICK HERE>'
      }
    }
  end

  it_behaves_like Integrations::ChatMessage

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
      it 'returns a slack-link sanitized message regarding opening of issues' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Title> opened by Test User (test.user)')
        expect(subject.attachments).to eq(
          [
            {
              title: "#100 Title",
              title_link: "http://url.com",
              text: "issue description &lt;http://custom-url.com|CLICK HERE&gt;",
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
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Title> closed by Test User (test.user)')
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
          .to eq('[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Title> opened by Test User (test.user)')
        expect(subject.attachments).to be_empty
      end
    end

    context 'when project_name is blank' do
      before do
        args[:project_name] = ''
      end

      it 'returns message without project' do
        expect(subject.pretext).to eq('Issue <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'returns activity without subtitle' do
        expect(subject.activity).to eq({
          title: 'Issue opened by Test User (test.user)',
          subtitle: '',
          text: '[#100 Title](http://url.com)',
          image: 'http://someavatar.com'
        })
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
          '[[project_name](http://somewhere.com)] Issue [#100 Title](http://url.com) opened by Test User (test.user)')
        expect(subject.attachments).to eq('issue description &lt;http://custom-url.com|CLICK HERE&gt;')
        expect(subject.activity).to eq({
          title: 'Issue opened by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[#100 Title](http://url.com)',
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
        expect(subject.pretext).to eq(
          '[[project_name](http://somewhere.com)] Issue [#100 Title](http://url.com) closed by Test User (test.user)')
        expect(subject.attachments).to be_empty
        expect(subject.activity).to eq({
          title: 'Issue closed by Test User (test.user)',
          subtitle: 'in [project_name](http://somewhere.com)',
          text: '[#100 Title](http://url.com)',
          image: 'http://someavatar.com'
        })
      end
    end

    context 'when project_name is blank' do
      before do
        args[:project_name] = ''
      end

      it 'returns message without project' do
        expect(subject.pretext).to eq('Issue [#100 Title](http://url.com) opened by Test User (test.user)')
      end

      it 'returns activity without subtitle' do
        expect(subject.activity).to eq({
          title: 'Issue opened by Test User (test.user)',
          subtitle: '',
          text: '[#100 Title](http://url.com)',
          image: 'http://someavatar.com'
        })
      end
    end
  end

  describe 'issue and work item types' do
    context 'with issue' do
      it 'uses Issue in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses Issue in activity title' do
        expect(subject.activity[:title]).to eq('Issue opened by Test User (test.user)')
      end
    end

    context 'with incident' do
      before do
        args[:object_kind] = 'incident'
      end

      it 'uses Incident in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Incident <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses Incident in activity title' do
        expect(subject.activity[:title]).to eq('Incident opened by Test User (test.user)')
      end
    end

    context 'with issue work item' do
      before do
        args[:object_kind] = 'work_item'
        args[:object_attributes][:type] = 'Issue'
      end

      it 'uses Issue in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Issue <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses Issue in activity title' do
        expect(subject.activity[:title]).to eq('Issue opened by Test User (test.user)')
      end
    end

    context 'with ticket work item' do
      before do
        args[:object_kind] = 'work_item'
        args[:object_attributes][:type] = 'Ticket'
      end

      it 'uses Ticket in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Ticket <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses Ticket in activity title' do
        expect(subject.activity[:title]).to eq('Ticket opened by Test User (test.user)')
      end
    end

    context 'with incident work item' do
      before do
        args[:object_kind] = 'work_item'
        args[:object_attributes][:type] = 'Incident'
      end

      it 'uses Incident in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Incident <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses Incident in activity title' do
        expect(subject.activity[:title]).to eq('Incident opened by Test User (test.user)')
      end
    end

    context 'with confidential work item' do
      before do
        args[:object_kind] = 'confidential_work_item'
        args[:object_attributes][:type] = 'Task'
      end

      it 'uses work item type in pretext' do
        expect(subject.pretext).to eq(
          '[<http://somewhere.com|project_name>] Task <http://url.com|#100 Title> opened by Test User (test.user)')
      end

      it 'uses work item type in activity title' do
        expect(subject.activity[:title]).to eq('Task opened by Test User (test.user)')
      end
    end
  end

  describe '#attachment_color' do
    it 'returns the correct color' do
      expect(subject.attachment_color).to eq('#C95823')
    end
  end

  describe '#issue_type' do
    context 'with issue' do
      it 'returns Issue' do
        expect(subject.issue_type).to eq('Issue')
      end
    end

    context 'with incident' do
      before do
        args[:object_kind] = 'incident'
      end

      it 'returns Incident' do
        expect(subject.issue_type).to eq('Incident')
      end
    end

    context 'with work item' do
      before do
        args[:object_kind] = 'work_item'
        args[:object_attributes][:type] = 'Task'
      end

      it 'returns the work item type' do
        expect(subject.issue_type).to eq('Task')
      end
    end

    context 'with confidential work item' do
      before do
        args[:object_kind] = 'confidential_work_item'
        args[:object_attributes][:type] = 'Task'
      end

      it 'returns the work item type' do
        expect(subject.issue_type).to eq('Task')
      end
    end
  end
end
