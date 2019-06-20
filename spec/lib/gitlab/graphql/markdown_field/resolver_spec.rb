# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::Graphql::MarkdownField::Resolver do
  include Gitlab::Routing
  let(:resolver) { described_class.new(:note) }

  describe '#proc' do
    let(:project) { create(:project, :public) }
    let(:issue) { create(:issue, project: project) }
    let(:note) do
      create(:note,
             note: "Referencing #{issue.to_reference(full: true)}")
    end

    it 'renders markdown correctly' do
      expect(resolver.proc.call(note, {}, {})).to include(issue_path(issue))
    end

    context 'when the issue is not publicly accessible' do
      let(:project) { create(:project, :private) }

      it 'hides the references from users that are not allowed to see the reference' do
        expect(resolver.proc.call(note, {}, {})).not_to include(issue_path(issue))
      end

      it 'shows the reference to users that are allowed to see it' do
        expect(resolver.proc.call(note, {}, { current_user: project.owner }))
          .to include(issue_path(issue))
      end
    end
  end
end
