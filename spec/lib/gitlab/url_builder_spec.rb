# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::UrlBuilder do
  subject { described_class }

  describe '#build' do
    it 'delegates to the class method' do
      expect(subject).to receive(:build).with(:foo, bar: :baz)

      subject.instance.build(:foo, bar: :baz)
    end
  end

  describe '.build' do
    using RSpec::Parameterized::TableSyntax

    where(:factory, :path_generator) do
      :project           | ->(project)       { "/#{project.full_path}" }
      :board             | ->(board)         { "/#{board.project.full_path}/-/boards/#{board.id}" }
      :group_board       | ->(board)         { "/groups/#{board.group.full_path}/-/boards/#{board.id}" }
      :commit            | ->(commit)        { "/#{commit.project.full_path}/-/commit/#{commit.id}" }
      :issue             | ->(issue)         { "/#{issue.project.full_path}/-/issues/#{issue.iid}" }
      [:issue, :task]    | ->(issue)         { "/#{issue.project.full_path}/-/work_items/#{issue.iid}" }
      [:work_item, :task]     | ->(work_item)    { "/#{work_item.project.full_path}/-/work_items/#{work_item.iid}" }
      [:work_item, :issue]    | ->(work_item)    { "/#{work_item.project.full_path}/-/issues/#{work_item.iid}" }
      [:work_item, :incident] | ->(work_item)    { "/#{work_item.project.full_path}/-/issues/#{work_item.iid}" }
      :merge_request     | ->(merge_request) { "/#{merge_request.project.full_path}/-/merge_requests/#{merge_request.iid}" }
      :project_milestone | ->(milestone)     { "/#{milestone.project.full_path}/-/milestones/#{milestone.iid}" }
      :project_snippet   | ->(snippet)       { "/#{snippet.project.full_path}/-/snippets/#{snippet.id}" }
      :project_wiki      | ->(wiki)          { "/#{wiki.container.full_path}/-/wikis/home" }
      :release           | ->(release)       { "/#{release.project.full_path}/-/releases/#{release.tag}" }
      :organization      | ->(organization)  { "/-/organizations/#{organization.path}" }
      :ci_build          | ->(build)         { "/#{build.project.full_path}/-/jobs/#{build.id}" }
      :ci_pipeline       | ->(pipeline)      { "/#{pipeline.project.full_path}/-/pipelines/#{pipeline.id}" }
      :design            | ->(design)        { "/#{design.project.full_path}/-/design_management/designs/#{design.id}/raw_image" }

      [:issue, :group_level]     | ->(issue)     { "/groups/#{issue.namespace.full_path}/-/work_items/#{issue.iid}" }
      [:work_item, :group_level] | ->(work_item) { "/groups/#{work_item.namespace.full_path}/-/work_items/#{work_item.iid}" }

      :group             | ->(group)         { "/groups/#{group.full_path}" }
      :group_milestone   | ->(milestone)     { "/groups/#{milestone.group.full_path}/-/milestones/#{milestone.iid}" }

      :user              | ->(user)          { "/#{user.full_path}" }
      :personal_snippet  | ->(snippet)       { "/-/snippets/#{snippet.id}" }
      :wiki_page         | ->(wiki_page)     { "#{wiki_page.wiki.wiki_base_path}/#{wiki_page.slug}" }

      :note_on_commit                      | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :diff_note_on_commit                 | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :discussion_note_on_commit           | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }
      :legacy_diff_note_on_commit          | ->(note) { "/#{note.project.full_path}/-/commit/#{note.commit_id}#note_#{note.id}" }

      :note_on_issue                       | ->(note) { "/#{note.project.full_path}/-/issues/#{note.noteable.iid}#note_#{note.id}" }
      :discussion_note_on_issue            | ->(note) { "/#{note.project.full_path}/-/issues/#{note.noteable.iid}#note_#{note.id}" }

      :note_on_merge_request               | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :diff_note_on_merge_request          | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :discussion_note_on_merge_request    | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }
      :legacy_diff_note_on_merge_request   | ->(note) { "/#{note.project.full_path}/-/merge_requests/#{note.noteable.iid}#note_#{note.id}" }

      :note_on_project_snippet             | ->(note) { "/#{note.project.full_path}/-/snippets/#{note.noteable_id}#note_#{note.id}" }
      :discussion_note_on_project_snippet  | ->(note) { "/#{note.project.full_path}/-/snippets/#{note.noteable_id}#note_#{note.id}" }
      :discussion_note_on_personal_snippet | ->(note) { "/-/snippets/#{note.noteable_id}#note_#{note.id}" }
      :note_on_personal_snippet            | ->(note) { "/-/snippets/#{note.noteable_id}#note_#{note.id}" }
      :package                             | ->(package) { "/#{package.project.full_path}/-/packages/#{package.id}" }
      :user_namespace                      | ->(user_namespace) { "/#{user_namespace.owner.full_path}" }
      :project_namespace                   | ->(project_namespace) { "/#{project_namespace.project.full_path}" }
      :abuse_report_note                   | ->(note) { "/admin/abuse_reports/#{note.abuse_report_id}#anti_abuse_reports_note_#{note.id}" }
    end

    with_them do
      let(:object) { build_stubbed(*Array(factory)) }
      let(:path) { path_generator.call(object) }

      it 'returns the full URL' do
        expect(subject.build(object)).to eq("#{Gitlab.config.gitlab.url}#{path}")
      end

      it 'returns only the path if only_path is given' do
        expect(subject.build(object, only_path: true)).to eq(path)
      end
    end

    context 'when passing a Service Desk issue', feature_category: :service_desk do
      let(:service_desk_issue) { create(:work_item, :issue, author: Users::Internal.support_bot) }

      subject { described_class.build(service_desk_issue, only_path: true) }

      it { is_expected.to eq("/#{service_desk_issue.project.full_path}/-/issues/#{service_desk_issue.iid}") }
    end

    context 'when passing a wiki note' do
      let_it_be(:wiki_page_slug) { create(:wiki_page_slug, canonical: true) }
      let(:wiki_page_meta) { wiki_page_slug.reload.wiki_page_meta }
      let(:note) { build_stubbed(:note, noteable: wiki_page_meta, project: wiki_page_meta.project) }

      let(:path) { "/#{note.project.full_path}/-/wikis/#{note.noteable.canonical_slug}#note_#{note.id}" }

      it 'returns the full URL' do
        expect(subject.build(note)).to eq("#{Gitlab.config.gitlab.url}#{path}")
      end

      it 'returns only the path if only_path is given' do
        expect(subject.build(note, only_path: true)).to eq(path)
      end
    end

    context 'when passing a wiki page meta object' do
      # NOTE: `build_stubbed` doesn't work for wiki_page_meta properly at the moment
      let_it_be(:wiki_page_meta) { create(:wiki_page_meta, :for_wiki_page) }

      it 'returns the full URL' do
        path = "#{wiki_page_meta.container.wiki.wiki_base_path}/#{wiki_page_meta.canonical_slug}"

        expect(subject.build(wiki_page_meta)).to eq("#{Gitlab.config.gitlab.url}#{path}")
      end
    end

    context 'when passing a compare' do
      # NOTE: The Compare requires an actual repository, which isn't available
      # with the `build_stubbed` strategy used by the table tests above
      let_it_be(:compare) { create(:compare) }
      let_it_be(:project) { compare.project }

      it 'returns the full URL' do
        expect(subject.build(compare)).to eq("#{Gitlab.config.gitlab.url}/#{project.full_path}/-/compare/#{compare.base_commit_sha}...#{compare.head_commit_sha}")
      end

      it 'returns only the path if only_path is given' do
        expect(subject.build(compare, only_path: true)).to eq("/#{project.full_path}/-/compare/#{compare.base_commit_sha}...#{compare.head_commit_sha}")
      end

      it 'returns an empty string for missing project' do
        expect(compare).to receive(:project).and_return(nil)

        expect(subject.build(compare)).to eq('')
      end
    end

    context 'when passing a commit without a project' do
      let(:commit) { build_stubbed(:commit) }

      it 'returns an empty string' do
        allow(commit).to receive(:project).and_return(nil)

        expect(subject.build(commit)).to eq('')
      end
    end

    context 'when passing a commit note without a project' do
      let(:note) { build_stubbed(:note_on_commit) }

      it 'returns an empty string' do
        allow(note).to receive(:project).and_return(nil)

        expect(subject.build(note)).to eq('')
      end
    end

    context 'when passing a Snippet' do
      let_it_be(:personal_snippet) { create(:personal_snippet, :repository) }
      let_it_be(:project_snippet)  { create(:project_snippet, :repository) }

      let(:blob)                   { snippet.blobs.first }
      let(:ref)                    { blob.repository.root_ref }

      context 'for a PersonalSnippet' do
        let(:snippet) { personal_snippet }

        it 'returns a raw snippet URL if requested' do
          url = subject.build(snippet, raw: true)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/-/snippets/#{snippet.id}/raw"
        end

        it 'returns a raw snippet blob URL if requested' do
          url = subject.build(snippet, file: blob.path, ref: ref)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"
        end
      end

      context 'for a ProjectSnippet' do
        let(:snippet) { project_snippet }

        it 'returns a raw snippet URL if requested' do
          url = subject.build(snippet, raw: true)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw"
        end

        it 'returns a raw snippet blob URL if requested' do
          url = subject.build(snippet, file: blob.path, ref: ref)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{snippet.project.full_path}/-/snippets/#{snippet.id}/raw/#{ref}/#{blob.path}"
        end
      end
    end

    context 'when passing a Wiki' do
      let(:wiki) { build_stubbed(:project_wiki) }

      describe '#wiki_url' do
        it 'uses the default collection action' do
          url = subject.wiki_url(wiki)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{wiki.project.full_path}/-/wikis/home"
        end

        it 'supports a custom collection action' do
          url = subject.wiki_url(wiki, action: :pages)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{wiki.project.full_path}/-/wikis/pages"
        end
      end

      describe '#wiki_page_url' do
        it 'uses the default member action' do
          url = subject.wiki_page_url(wiki, 'foo')

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{wiki.project.full_path}/-/wikis/foo"
        end

        it 'supports a custom member action' do
          url = subject.wiki_page_url(wiki, 'foo', action: :edit)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{wiki.project.full_path}/-/wikis/foo/edit"
        end
      end
    end

    context 'when passing Packages::Package' do
      let(:package) { build_stubbed(:terraform_module_package) }

      context 'with terraform module package' do
        it 'returns the url for terraform module registry' do
          url = subject.build(package)

          expect(url).to eq "#{Gitlab.config.gitlab.url}/#{package.project.full_path}/-/terraform_module_registry/#{package.id}"
        end
      end
    end

    context 'when passing a DesignManagement::Design' do
      let(:design) { build_stubbed(:design) }

      it 'uses the given ref and size in the URL' do
        url = subject.build(design, ref: 'feature', size: 'small')

        expect(url).to eq "#{Settings.gitlab['url']}/#{design.project.full_path}/-/design_management/designs/#{design.id}/feature/resized_image/small"
      end
    end

    context 'when passing an unsupported class' do
      let(:object) { Object.new }

      it 'raises an exception' do
        expect { subject.build(object) }.to raise_error(NotImplementedError)
      end
    end

    context 'when passing a batch loaded model' do
      let(:project) { build_stubbed(:project) }
      let(:object) do
        BatchLoader.for(:project).batch do |batch, loader|
          batch.each { |_| loader.call(:project, project) }
        end
      end

      it 'returns the URL for the real object' do
        expect(subject.build(object, only_path: true)).to eq("/#{project.full_path}")
      end
    end
  end
end
