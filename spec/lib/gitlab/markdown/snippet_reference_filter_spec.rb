require 'spec_helper'

module Gitlab::Markdown
  describe SnippetReferenceFilter do
    include FilterSpecHelper

    let(:project)   { create(:empty_project) }
    let(:snippet)   { create(:project_snippet, project: project) }
    let(:reference) { snippet.to_reference }

    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Snippet #{reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    context 'internal reference' do
      it 'links to a valid reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq urls.
          namespace_project_snippet_url(project.namespace, project, snippet)
      end

      it 'links with adjacent text' do
        doc = filter("Snippet (#{reference}.)")
        expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
      end

      it 'ignores invalid snippet IDs' do
        exp = act = "Snippet #{invalidate_reference(reference)}"

        expect(filter(act).to_html).to eq exp
      end

      it 'includes a title attribute' do
        doc = filter("Snippet #{reference}")
        expect(doc.css('a').first.attr('title')).to eq "Snippet: #{snippet.title}"
      end

      it 'escapes the title attribute' do
        snippet.update_attribute(:title, %{"></a>whatever<a title="})

        doc = filter("Snippet #{reference}")
        expect(doc.text).to eq "Snippet #{reference}"
      end

      it 'includes default classes' do
        doc = filter("Snippet #{reference}")
        expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-snippet'
      end

      it 'includes an optional custom class' do
        doc = filter("Snippet #{reference}", reference_class: 'custom')
        expect(doc.css('a').first.attr('class')).to include 'custom'
      end

      it 'includes a data-project-id attribute' do
        doc = filter("Snippet #{reference}")
        link = doc.css('a').first

        expect(link).to have_attribute('data-project-id')
        expect(link.attr('data-project-id')).to eq project.id.to_s
      end

      it 'supports an :only_path context' do
        doc = filter("Snippet #{reference}", only_path: true)
        link = doc.css('a').first.attr('href')

        expect(link).not_to match %r(https?://)
        expect(link).to eq urls.namespace_project_snippet_url(project.namespace, project, snippet, only_path: true)
      end

      it 'adds to the results hash' do
        result = pipeline_result("Snippet #{reference}")
        expect(result[:references][:snippet]).to eq [snippet]
      end
    end

    context 'cross-project reference' do
      let(:namespace) { create(:namespace, name: 'cross-reference') }
      let(:project2)  { create(:empty_project, namespace: namespace) }
      let(:snippet)   { create(:project_snippet, project: project2) }
      let(:reference) { snippet.to_reference(project) }

      context 'when user can access reference' do
        before { allow_cross_reference! }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).
            to eq urls.namespace_project_snippet_url(project2.namespace, project2, snippet)
        end

        it 'links with adjacent text' do
          doc = filter("See (#{reference}.)")
          expect(doc.to_html).to match(/\(<a.+>#{Regexp.escape(reference)}<\/a>\.\)/)
        end

        it 'ignores invalid snippet IDs on the referenced project' do
          exp = act = "See #{invalidate_reference(reference)}"

          expect(filter(act).to_html).to eq exp
        end

        it 'adds to the results hash' do
          result = pipeline_result("Snippet #{reference}")
          expect(result[:references][:snippet]).to eq [snippet]
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
