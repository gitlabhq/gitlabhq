# frozen_string_literal: true

require 'spec_helper'
require 'set'

RSpec.describe WikiDirectory do
  include GitHelpers

  let(:project) { create(:project, :wiki_repo) }
  let(:user) { project.owner }
  let(:wiki) { ProjectWiki.new(project, user) }

  describe 'validations' do
    subject { build(:wiki_directory) }

    it { is_expected.to validate_presence_of(:slug) }
  end

  describe '.group_by_directory' do
    context 'when there are no pages' do
      it 'returns an empty array' do
        expect(described_class.group_by_directory(nil)).to eq([])
        expect(described_class.group_by_directory([])).to eq([])
      end
    end

    context 'when there are pages' do
      before do
        create_page('dir_1/dir_1_1/page_3', 'content')
        create_page('page_1', 'content')
        create_page('dir_1/page_2', 'content')
        create_page('dir_2', 'page with dir name')
        create_page('dir_2/page_5', 'content')
        create_page('page_6', 'content')
        create_page('dir_2/page_4', 'content')
      end

      let(:page_1) { wiki.find_page('page_1') }
      let(:page_6) { wiki.find_page('page_6') }
      let(:page_dir_2) { wiki.find_page('dir_2') }

      let(:dir_1) do
        described_class.new('dir_1', [wiki.find_page('dir_1/page_2')])
      end
      let(:dir_1_1) do
        described_class.new('dir_1/dir_1_1', [wiki.find_page('dir_1/dir_1_1/page_3')])
      end
      let(:dir_2) do
        pages = [wiki.find_page('dir_2/page_5'),
                 wiki.find_page('dir_2/page_4')]
        described_class.new('dir_2', pages)
      end

      context "#list_pages" do
        shared_examples "a correct grouping" do
          let(:grouped_slugs) { grouped_entries.map(&method(:slugs)) }
          let(:expected_slugs) { expected_grouped_entries.map(&method(:slugs)).map(&method(:match_array)) }

          it 'returns an array with pages and directories' do
            expect(grouped_slugs).to match_array(expected_slugs)
          end
        end

        context 'sort by title' do
          let(:grouped_entries) { described_class.group_by_directory(wiki.list_pages) }

          let(:expected_grouped_entries) { [dir_1_1, dir_1, page_dir_2, dir_2, page_1, page_6] }

          it_behaves_like "a correct grouping"
        end

        context 'sort by created_at' do
          let(:grouped_entries) { described_class.group_by_directory(wiki.list_pages(sort: 'created_at')) }
          let(:expected_grouped_entries) { [dir_1_1, page_1, dir_1, page_dir_2, dir_2, page_6] }

          it_behaves_like "a correct grouping"
        end

        it 'returns an array with retained order with directories at the top' do
          expected_order = ['dir_1/dir_1_1/page_3', 'dir_1/page_2', 'dir_2', 'dir_2/page_4', 'dir_2/page_5', 'page_1', 'page_6']

          grouped_entries = described_class.group_by_directory(wiki.list_pages)

          actual_order = grouped_entries.flat_map(&method(:slugs))

          expect(actual_order).to eq(expected_order)
        end
      end
    end
  end

  describe '#initialize' do
    context 'when there are pages' do
      let(:pages) { [build(:wiki_page)] }
      let(:directory) { described_class.new('/path_up_to/dir', pages) }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute' do
        expect(directory.pages).to eq(pages)
      end
    end

    context 'when there are no pages' do
      let(:directory) { described_class.new('/path_up_to/dir') }

      it 'sets the slug attribute' do
        expect(directory.slug).to eq('/path_up_to/dir')
      end

      it 'sets the pages attribute to an empty array' do
        expect(directory.pages).to eq([])
      end
    end
  end

  describe '#to_partial_path' do
    it 'returns the relative path to the partial to be used' do
      directory = build(:wiki_directory)

      expect(directory.to_partial_path).to eq('projects/wiki_directories/wiki_directory')
    end
  end

  describe 'attributes' do
    def page_path(index)
      "dir-path/page-#{index}"
    end

    let(:page_paths) { (1..3).map { |n| page_path(n) } }

    let(:pages) do
      page_paths.map { |p| wiki.find_page(p) }
    end

    subject { described_class.new('dir-path', pages) }

    context 'there are no pages' do
      let(:pages) { [] }

      it { is_expected.to have_attributes(page_count: 0, last_version: be_nil) }
    end

    context 'there is one page' do
      before do
        create_page("dir-path/singleton", "Just this page")
      end

      let(:the_page) { wiki.find_page("dir-path/singleton") }
      let(:pages) { [the_page] }

      it { is_expected.to have_attributes(page_count: 1, last_version: the_page.last_version) }
    end

    context 'there are a few pages, each with a single version' do
      before do
        page_paths.each_with_index do |path, n|
          Timecop.freeze(Time.local(1990) + n.minutes) do
            create_page(path, "this is page #{n}")
          end
        end
      end

      let(:expected_last_version) { pages.last.last_version }

      it { is_expected.to have_attributes(page_count: 3, last_version: expected_last_version) }
    end

    context 'there are a few pages, each with a few versions' do
      before do
        page_paths.each_with_index do |path, n|
          t = Time.local(1990) + n.minutes
          Timecop.freeze(t) do
            create_page(path, "This is page #{n}")
            (2..3).each do |v|
              Timecop.freeze(t + v.seconds) do
                update_page(path, "Now at version #{v}")
              end
            end
          end
        end
      end

      it { is_expected.to have_attributes(page_count: 3, last_version: pages.last.last_version) }
    end
  end

  private

  def create_page(name, content)
    wiki.wiki.write_page(name, :markdown, content, commit_details)
    set_time(name)
  end

  def update_page(name, content)
    wiki.wiki.update_page(name, name, :markdown, content, update_commit_details)
    set_time(name)
  end

  def set_time(name)
    return unless Timecop.frozen?

    new_date = Time.now
    page = wiki.find_page(name).page
    commit = page.version.commit
    repo = commit.instance_variable_get(:@repository)

    rug_commit = rugged_repo_at_path(repo.relative_path).lookup(commit.id)
    rug_commit.amend(
      message: rug_commit.message,
      tree: rug_commit.tree,
      author: rug_commit.author.merge(time: new_date),
      committer: rug_commit.committer.merge(time: new_date),
      update_ref: 'HEAD'
    )
  end

  def commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "test commit")
  end

  def update_commit_details
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "test update")
  end

  def slugs(thing)
    Array.wrap(thing.respond_to?(:pages) ? thing.pages.map(&:slug) : thing.slug)
  end
end
