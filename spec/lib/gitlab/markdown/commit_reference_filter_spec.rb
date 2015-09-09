require 'spec_helper'

module Gitlab::Markdown
  describe CommitReferenceFilter do
    include FilterSpecHelper

    let(:project) { create(:project) }
    let(:commit)  { project.commit }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
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

          expect(doc.css('a').first.text).to eq commit.short_id
          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_commit_url(project.namespace, project, reference)
        end
      end

      it 'always uses the short ID as the link text' do
        doc = filter("See #{commit.id}")
        expect(doc.text).to eq "See #{commit.short_id}"

        doc = filter("See #{commit.id[0...6]}")
        expect(doc.text).to eq "See #{commit.short_id}"
      end

      it 'links with adjacent text' do
        doc = filter("See (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{commit.short_id}<\/a>\.\)/)
      end

      it 'ignores invalid commit IDs' do
        invalid = invalidate_reference(reference)
        exp = act = "See #{invalid}"

        expect(project).to receive(:valid_repo?).and_return(true)
        expect(project.repository).to receive(:commit).with(invalid)
        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('title')).to eq commit.link_title
      end

      it 'escapes the title attribute' do
        allow_any_instance_of(Commit).to receive(:title).and_return(%{"></a>whatever<a title="})

        doc = filter("See #{reference}")
        expect(doc.text).to eq "See #{commit.short_id}"
      end

      it 'includes default classes' do
        doc = filter("See #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-commit'
      end

      it 'includes a data-project-id attribute' do
        doc = filter("See #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-project-id')
        expect(link.attr('data-project-id')).to eq project.id.to_s
      end

      it 'supports an :only_path context' do
        doc = filter("See #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_commit_url(project.namespace, project, reference, only_path: true)
      end

      it 'adds to the results hash' do
        result = pipeline_result("See #{reference}")
        expect(result[:references][:commit]).not_to be_empty
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:project, namespace: namespace) }
      let(:commit)    { project2.commit }
      let(:reference) { commit.to_reference(project) }

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_commit_url(project2.namespace, project2, commit.id)
        end

        it 'links with adjacent text' do
          doc = filter("Fixed (#{reference}.)")

          exp = Regexp.escape(project2.to_reference)
          expect(doc.to_html).to match(/\(<a.+>#{exp}@#{commit.short_id}<\/a>\.\)/)
        end

        it 'ignores invalid commit IDs on the referenced project' do
          exp = act = "Committed #{invalidate_reference(reference)}"
          expect(filter(act).to_html).to eq exp
        end

        it 'adds to the results hash' do
          result = pipeline_result("See #{reference}")
          expect(result[:references][:commit]).not_to be_empty
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
