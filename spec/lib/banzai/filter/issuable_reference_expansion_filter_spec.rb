# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::IssuableReferenceExpansionFilter, feature_category: :markdown do
  include FilterSpecHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :public) }
  let_it_be(:group) { create(:group) }
  let_it_be(:other_project) { create(:project, :public) }
  let_it_be(:closed_issue) { create_issue(:closed) }

  let(:context) { { current_user: user, issuable_reference_expansion_enabled: true } }

  def create_link(text, data)
    ActionController::Base.helpers.link_to(text, '', class: 'gfm has-tooltip', data: data)
  end

  def create_issue(state, attributes = {})
    create(:issue, state, attributes.merge(project: project))
  end

  def create_item(issuable_type, state, attributes = {})
    create(issuable_type, state, attributes.merge(project: project))
  end

  def create_merge_request(state, attributes = {})
    create(:merge_request, state, attributes.merge(source_project: project, target_project: project))
  end

  it 'ignores non-GFM links' do
    html = %(See <a href="https://google.com/">Google</a>)
    doc = filter(html, current_user: user)

    expect(doc.css('a').last.text).to eq('Google')
  end

  it 'ignores non-issuable links' do
    link = create_link('text', project: project.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  it 'ignores issuable links with empty content' do
    link = create_link('', issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('')
  end

  it 'ignores issuable links with custom anchor' do
    link = create_link('something', issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('something')
  end

  it 'ignores issuable links to specific comments' do
    link = create_link("#{closed_issue.to_reference} (comment 1)", issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference} (comment 1)")
  end

  it 'ignores merge request links to diffs tab' do
    merge_request = create(:merge_request, :closed)
    link = create_link(
      "#{merge_request.to_reference} (diffs)",
      merge_request: merge_request.id,
      reference_type: 'merge_request'
    )
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (diffs)")
  end

  it 'handles cross project references' do
    link = create_link(closed_issue.to_reference(other_project), issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: other_project))

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference(other_project)} (closed)")
  end

  it 'handles references from group scopes' do
    link = create_link(closed_issue.to_reference(other_project), issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: nil, group: group))

    expect(doc.css('a').last.text).to eq("#{closed_issue.to_reference(other_project)} (closed)")
  end

  it 'skips cross project references if the user cannot read cross project' do
    expect(Ability).to receive(:allowed?).with(user, :read_cross_project) { false }
    link = create_link(closed_issue.to_reference(other_project), issue: closed_issue.id, reference_type: 'issue')
    doc = filter(link, context.merge(project: other_project))

    expect(doc.css('a').last.text).to eq(closed_issue.to_reference(other_project).to_s)
  end

  it 'does not append state when filter is not enabled' do
    link = create_link('text', issue: closed_issue.id, reference_type: 'issue')
    context = { current_user: user }
    doc = filter(link, context)

    expect(doc.css('a').last.text).to eq('text')
  end

  context 'when project is in pending delete' do
    before do
      project.update!(pending_delete: true)
    end

    it 'does not append issue state' do
      link = create_link('text', issue: closed_issue.id, reference_type: 'issue')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq('text')
    end
  end

  shared_examples 'issue / work item references' do
    it 'ignores open references' do
      issuable = create_item(issuable_type, :opened)
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type)
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(issuable.to_reference)
    end

    it 'appends state to moved references' do
      moved_issuable = create_item(issuable_type, :closed, project: project,
        moved_to: create_item(issuable_type, :opened))
      link = create_link(moved_issuable.to_reference, "#{issuable_type}": moved_issuable.id,
        reference_type: issuable_type)
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{moved_issuable.to_reference} (moved)")
    end

    it 'appends state to closed references' do
      issuable = create_item(issuable_type, :closed)
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type)
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issuable.to_reference} (closed)")
    end

    it 'shows title for references with +' do
      issuable = create_item(issuable_type, :opened, title: 'Some issue')
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type,
        reference_format: '+')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issuable.title} (#{issuable.to_reference})")
    end

    it 'truncates long title for references with +' do
      issuable = create_item(issuable_type, :opened, title: 'Some issue ' * 10)
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type,
        reference_format: '+')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issuable.title.truncate(50)} (#{issuable.to_reference})")
    end

    it 'shows both title and state for closed references with +' do
      issuable = create_item(issuable_type, :closed, title: 'Some issue')
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type,
        reference_format: '+')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issuable.title} (#{issuable.to_reference} - closed)")
    end

    context 'for references with fenced emoji' do
      def issuable_link(issuable)
        create_link(
          issuable.to_reference,
          "#{issuable_type}": issuable.id,
          reference_type: issuable_type,
          reference_format: '+'
        )
      end

      it 'expands emoji for references with +' do
        issuable = create_item(issuable_type, :opened, title: 'Some issue :eagle:')
        doc = filter(issuable_link(issuable), context)

        expect(/\p{Emoji_Presentation}/ =~ doc.css('a').last.text).not_to be_nil
        expect(doc.css('a').last.text.scan(/\p{Emoji_Presentation}/)).to eq(["🦅"])
      end

      it 'expands when emoji is embedded at the beginning of a string' do
        issuable = create_item(issuable_type, :opened, title: ':eagle: Some issue')
        doc = filter(issuable_link(issuable), context)

        expect(/\p{Emoji_Presentation}/ =~ doc.css('a').last.text).not_to be_nil
        expect(doc.css('a').last.text.scan(/\p{Emoji_Presentation}/)).to eq(["🦅"])
      end

      it 'expands when emoji appears multiple times' do
        issuable = create_item(issuable_type, :opened, title: ':eagle: Some issue :dog:')
        doc = filter(issuable_link(issuable), context)

        expect(/\p{Emoji_Presentation}/ =~ doc.css('a').last.text).not_to be_nil
        expect(doc.css('a').last.text.scan(/\p{Emoji_Presentation}/)).to eq(["🦅", "🐶"])
      end

      it 'does not expand when emoji is embedded mid-string' do
        issuable = create_item(issuable_type, :opened, title: 'Some:eagle:issue')
        doc = filter(issuable_link(issuable), context)

        expect(/\p{Emoji_Presentation}/ =~ doc.css('a').last.text).to be_nil
      end
    end

    it 'shows title for references with +s' do
      issuable = create_item(issuable_type, :opened, title: 'Some issue')
      link = create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type,
        reference_format: '+s')
      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{issuable.title} (#{issuable.to_reference}) • Unassigned")
    end

    context 'when extended summary props are present' do
      let_it_be(:milestone) { create(:milestone, project: project) }
      let_it_be(:assignees) { create_list(:user, 3) }
      let_it_be(:issuable) do
        create_item(issuable_type, :opened, title: 'Some issue', milestone: milestone,
          assignees: assignees)
      end

      let_it_be(:link) do
        create_link(issuable.to_reference, "#{issuable_type}": issuable.id, reference_type: issuable_type,
          reference_format: '+s')
      end

      it 'shows extended summary for references with +s' do
        doc = filter(link, context)

        expect(doc.css('a').last.text).to eq(
          "#{issuable.title} (#{issuable.to_reference}) • #{assignees[0].name}, #{assignees[1].name}+ " \
          "• #{milestone.title}"
        )
      end

      describe 'checking N+1' do
        let_it_be(:milestone2) { create(:milestone, project: project) }
        let_it_be(:assignees2) { create_list(:user, 3) }

        it 'does not have N+1 for extended summary', :use_sql_query_cache do
          issuable2 = create_item(issuable_type, :opened, title: 'Another issue',
            milestone: milestone2, assignees: assignees2)
          link2 = create_link(issuable2.to_reference, "#{issuable_type}": issuable2.id,
            reference_type: issuable_type, reference_format: '+s')

          # warm up
          filter(link, context)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            filter(link, context)
          end

          expect(control.count).to eq 12

          expect do
            filter("#{link} #{link2}", context)
          end.not_to exceed_all_query_limit(control)
        end
      end
    end
  end

  context 'for work item references' do
    let_it_be(:issuable_type) { :work_item }

    it_behaves_like 'issue / work item references'
  end

  context 'for issue references' do
    let_it_be(:issuable_type) { :issue }

    it_behaves_like 'issue / work item references'
  end

  context 'for merge request references' do
    it 'ignores open merge request references' do
      merge_request = create_merge_request(:opened)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'ignores locked merge request references' do
      merge_request = create_merge_request(:locked)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq(merge_request.to_reference)
    end

    it 'appends state to closed merge request references' do
      merge_request = create_merge_request(:closed)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (closed)")
    end

    it 'appends state to merged merge request references' do
      merge_request = create_merge_request(:merged)

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.to_reference} (merged)")
    end

    it 'shows title for references with +' do
      merge_request = create_merge_request(:opened, title: 'Some merge request')

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request',
        reference_format: '+'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.title} (#{merge_request.to_reference})")
    end

    it 'shows title for references with +s' do
      merge_request = create_merge_request(:opened, title: 'Some merge request')

      link = create_link(
        merge_request.to_reference,
        merge_request: merge_request.id,
        reference_type: 'merge_request',
        reference_format: '+s'
      )

      doc = filter(link, context)

      expect(doc.css('a').last.text).to eq("#{merge_request.title} (#{merge_request.to_reference}) • Unassigned")
    end

    context 'when extended summary props are present' do
      let_it_be(:milestone) { create(:milestone, project: project) }
      let_it_be(:assignees) { create_list(:user, 2) }
      let_it_be(:merge_request) do
        create_merge_request(:opened, title: 'Some merge request', milestone: milestone, assignees: assignees)
      end

      let_it_be(:link) do
        create_link(
          merge_request.to_reference,
          merge_request: merge_request.id,
          reference_type: 'merge_request',
          reference_format: '+s'
        )
      end

      it 'shows extended summary for references with +s' do
        doc = filter(link, context)

        expect(doc.css('a').last.text).to eq(
          "#{merge_request.title} (#{merge_request.to_reference}) • #{assignees[0].name}, #{assignees[1].name} • " \
          "#{milestone.title}"
        )
      end

      describe 'checking N+1' do
        let_it_be(:milestone2) { create(:milestone, project: project) }
        let_it_be(:assignees2) { create_list(:user, 3) }

        it 'does not have N+1 for extended summary', :use_sql_query_cache do
          merge_request2 = create_merge_request(
            :closed,
            title: 'Some merge request',
            milestone: milestone2,
            assignees: assignees2
          )

          link2 = create_link(
            merge_request2.to_reference,
            merge_request: merge_request2.id,
            reference_type: 'merge_request',
            reference_format: '+s'
          )

          # warm up
          filter(link, context)

          control = ActiveRecord::QueryRecorder.new(skip_cached: false) do
            filter(link, context)
          end

          expect(control.count).to eq 10

          expect do
            filter("#{link} #{link2}", context)
          end.not_to exceed_all_query_limit(control)
        end
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
