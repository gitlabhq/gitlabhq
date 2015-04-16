require 'spec_helper'

module Gitlab::Markdown
  describe CommitReferenceFilter do
    include ReferenceFilterSpecHelper

    let(:project) { create(:project) }
    let(:commit)  { project.repository.commit }

    it 'requires project context' do
      expect { described_class.call('Commit 1c002d', {}) }.
        to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Commit #{commit.id}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      let(:reference) { commit.id }

      # Let's test a variety of commit SHA sizes just to be paranoid
      [6, 8, 12, 18, 20, 32, 40].each do |size|
        it "links to a valid reference of #{size} characters" do
          doc = filter("See #{reference[0...size]}")

          expect(doc.css('a').first.text).to eq reference[0...size]
          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_commit_url(project.namespace, project, reference)
        end
      end

      it 'links with adjacent text' do
        doc = filter("See (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
      end

      it 'ignores invalid commit IDs' do
        exp = act = "See #{reference.reverse}"

        expect(project).to receive(:valid_repo?).and_return(true)
        expect(project.repository).to receive(:commit).with(reference.reverse)
        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('title')).to eq commit.link_title
      end

      it 'escapes the title attribute' do
        allow_any_instance_of(Commit).to receive(:title).and_return(%{"></a>whatever<a title="})

        doc = filter("See #{reference}")
        expect(doc.text).to eq "See #{commit.id}"
      end

      it 'includes default classes' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit'
      end

      it 'includes an optional custom class' do
        doc = filter("See #{reference}", reference_class: 'custom')
        expect(doc.css('a').first.attr('class')).to include 'custom'
      end

      it 'supports an :only_path context' do
        doc = filter("See #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_commit_url(project.namespace, project, reference, only_path: true)
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:project, namespace: namespace) }
      let(:commit)    { project.repository.commit }
      let(:reference) { "#{project2.path_with_namespace}@#{commit.id}" }

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_commit_url(project2.namespace, project2, commit.id)
        end

        it 'links with adjacent text' do
          doc = filter("Fixed (#{reference}.)")
          expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
        end

        it 'ignores invalid commit IDs on the referenced project' do
          exp = act = "Committed #{project2.path_with_namespace}##{commit.id.reverse}"
          expect(filter(act).to_html).to eq exp
        end
      end

      context 'when user cannot access reference' do
        before { disallow_cross_reference! }

        it 'ignores valid references' do
          exp = act = "See #{reference}"

          expect(filter(act).to_html).to eq exp
        end
      end
    end
  end
end
