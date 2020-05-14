# frozen_string_literal: true

require 'spec_helper'

describe StateNote do
  describe '.from_event' do
    let_it_be(:author) { create(:user) }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:noteable) { create(:issue, author: author, project: project) }

    ResourceStateEvent.states.each do |state, _value|
      context "with event state #{state}" do
        let_it_be(:event) { create(:resource_state_event, issue: noteable, state: state, created_at: '2020-02-05') }

        subject { described_class.from_event(event, resource: noteable, resource_parent: project) }

        it_behaves_like 'a system note', exclude_project: true do
          let(:action) { state.to_s }
        end

        it 'contains the expected values' do
          expect(subject.author).to eq(author)
          expect(subject.created_at).to eq(event.created_at)
          expect(subject.note_html).to eq("<p dir=\"auto\">#{state}</p>")
        end
      end
    end
  end
end
