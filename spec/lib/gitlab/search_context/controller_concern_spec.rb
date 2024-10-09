# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SearchContext::ControllerConcern, type: :controller do
  controller(ApplicationController) do
    include Gitlab::SearchContext::ControllerConcern
  end

  let(:project) { nil }
  let(:group) { nil }
  let(:snippet) { nil }
  let(:snippets) { [] }
  let(:ref) { nil }

  let(:builder) { Gitlab::SearchContext::Builder.new(controller.view_context) }

  subject(:search_context) { controller.search_context }

  def weak_assign(ivar, value)
    return if value.nil?

    controller.instance_variable_set(ivar.to_sym, value)
  end

  before do
    weak_assign(:@project, project)
    weak_assign(:@group, group)
    weak_assign(:@ref, ref)
    weak_assign(:@snippet, snippet)
    weak_assign(:@snippets, snippets)

    allow(Gitlab::SearchContext::Builder).to receive(:new).and_return(builder)
  end

  shared_examples 'has the proper context' do
    it :aggregate_failures do
      expected_group = project ? project.group : group
      expected_snippets = [snippet, *snippets].compact

      expect(builder).to receive(:with_project).with(project).and_call_original if project
      expect(builder).to receive(:with_group).with(expected_group).and_call_original if expected_group
      expect(builder).to receive(:with_ref).with(ref).and_call_original if ref
      expected_snippets.each do |snippet|
        expect(builder).to receive(:with_snippet).with(snippet).and_call_original
      end

      is_expected.to be_a(Gitlab::SearchContext)
    end
  end

  context 'exposing @project' do
    let(:project) { create(:project) }

    it_behaves_like 'has the proper context'

    context 'when the project is owned by a group' do
      let(:project) { create(:project, group: create(:group)) }

      it_behaves_like 'has the proper context'
    end
  end

  context 'exposing @group' do
    let(:group) { create(:group) }

    it_behaves_like 'has the proper context'
  end

  context 'exposing @snippet, @snippets' do
    let(:snippet) { create(:project_snippet) }
    let(:snippets) { create_list(:project_snippet, 3) }

    it_behaves_like 'has the proper context'
  end

  context 'exposing @ref' do
    let(:ref) { Gitlab::Git::SHA1_EMPTY_TREE_ID }

    it_behaves_like 'has the proper context'
  end
end
