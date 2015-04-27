require 'spec_helper'
require 'html/pipeline'

module Gitlab::Markdown
  describe LabelReferenceFilter do
    include ReferenceFilterSpecHelper

    let(:project)   { create(:empty_project) }
    let(:label)     { create(:label, project: project) }
    let(:reference) { "~#{label.id}" }

    it 'requires project context' do
      expect { described_class.call('Label ~123', {}) }.
        to raise_error(ArgumentError, /:project/)
    end

    %w(pre code a style).each do |elem|
      it "ignores valid references contained inside '#{elem}' element" do
        exp = act = "<#{elem}>Label #{reference}</#{elem}>"
        expect(filter(act).to_html).to eq exp
      end
    end

    it 'includes default classes' do
      doc = filter("Label #{reference}")
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-label'
    end

    it 'includes an optional custom class' do
      doc = filter("Label #{reference}", reference_class: 'custom')
      expect(doc.css('a').first.attr('class')).to include 'custom'
    end

    it 'supports an :only_path context' do
      doc = filter("Label #{reference}", only_path: true)
      link = doc.css('a').first.attr('href')

      expect(link).not_to match %r(https?://)
      expect(link).to eq urls.namespace_project_issues_url(project.namespace, project, label_name: label.name, only_path: true)
    end

    it 'adds to the results hash' do
      result = pipeline_result("Label #{reference}")
      expect(result[:references][:label]).to eq [label]
    end

    describe 'label span element' do
      it 'includes default classes' do
        doc = filter("Label #{reference}")
        expect(doc.css('a span').first.attr('class')).to eq 'label color-label'
      end

      it 'includes a style attribute' do
        doc = filter("Label #{reference}")
        expect(doc.css('a span').first.attr('style')).to match(/\Abackground-color: #\h{6}; color: #\h{6}\z/)
      end
    end

    context 'Integer-based references' do
      it 'links to a valid reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq urls.
          namespace_project_issues_url(project.namespace, project, label_name: label.name)
      end

      it 'links with adjacent text' do
        doc = filter("Label (#{reference}.)")
        expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
      end

      it 'ignores invalid label IDs' do
        exp = act = "Label ~#{label.id + 1}"

        expect(filter(act).to_html).to eq exp
      end
    end

    context 'String-based single-word references' do
      let(:label)     { create(:label, name: 'gfm', project: project) }
      let(:reference) { "~#{label.name}" }

      it 'links to a valid reference' do
        doc = filter("See #{reference}")

        expect(doc.css('a').first.attr('href')).to eq urls.
          namespace_project_issues_url(project.namespace, project, label_name: label.name)
        expect(doc.text).to eq 'See gfm'
      end

      it 'links with adjacent text' do
        doc = filter("Label (#{reference}.)")
        expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
      end

      it 'ignores invalid label names' do
        exp = act = "Label ~#{label.name.reverse}"

        expect(filter(act).to_html).to eq exp
      end
    end

    context 'String-based multi-word references in quotes' do
      let(:label) { create(:label, name: 'gfm references', project: project) }

      context 'in single quotes' do
        let(:reference) { "~'#{label.name}'" }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).to eq urls.
            namespace_project_issues_url(project.namespace, project, label_name: label.name)
          expect(doc.text).to eq 'See gfm references'
        end

        it 'links with adjacent text' do
          doc = filter("Label (#{reference}.)")
          expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
        end

        it 'ignores invalid label names' do
          exp = act = "Label ~'#{label.name.reverse}'"

          expect(filter(act).to_html).to eq exp
        end
      end

      context 'in double quotes' do
        let(:reference) { %(~"#{label.name}") }

        it 'links to a valid reference' do
          doc = filter("See #{reference}")

          expect(doc.css('a').first.attr('href')).to eq urls.
            namespace_project_issues_url(project.namespace, project, label_name: label.name)
          expect(doc.text).to eq 'See gfm references'
        end

        it 'links with adjacent text' do
          doc = filter("Label (#{reference}.)")
          expect(doc.to_html).to match(%r(\(<a.+><span.+>#{label.name}</span></a>\.\)))
        end

        it 'ignores invalid label names' do
          exp = act = %(Label ~"#{label.name.reverse}")

          expect(filter(act).to_html).to eq exp
        end
      end
    end
  end
end
