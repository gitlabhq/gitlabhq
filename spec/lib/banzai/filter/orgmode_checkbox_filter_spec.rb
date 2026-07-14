# frozen_string_literal: true

require 'fast_spec_helper'
require 'html/pipeline'
require_relative '../../../support/shared_examples/lib/banzai/filters/filter_timeout_shared_examples'

RSpec.describe Banzai::Filter::OrgmodeCheckboxFilter, :aggregate_failures, feature_category: :markdown do
  def filter(html, context = {})
    described_class.call(html, { pipeline: :orgmode }.merge(context))
  end

  describe 'converts checkbox markers' do
    using RSpec::Parameterized::TableSyntax

    where(:list_tag) do
      [
        ['ul'],
        ['ol']
      ]
    end

    with_them do
      it 'converts nested mixed-state checkboxes' do
        html = <<~HTML
          <#{list_tag}>
            <li>[-] Parent Task [50%]
              <#{list_tag}>
                <li>[X] Subtask Done</li>
                <li>[ ] Subtask Pending</li>
              </#{list_tag}>
            </li>
          </#{list_tag}>
        HTML

        result = filter(html)

        inputs = result.css('li input')
        expect(inputs.size).to eq 3
        expect(inputs.map { |i| i['class'] }).to all eq 'task-list-item-checkbox'

        # [-]: indeterminate parent
        expect(inputs[0]['checked']).to be_nil
        expect(inputs[0]['data-indeterminate']).to eq 'true'

        # [X]: uppercase checked child
        expect(inputs[1]['checked']).to eq 'checked'

        # [ ]: unchecked child
        expect(inputs[2]['checked']).to be_nil
        expect(inputs[2]['data-indeterminate']).to be_nil

        lis = result.css('li.task-list-item')
        expect(lis.size).to eq 3

        task_lists = result.css("#{list_tag}.task-list")
        expect(task_lists.size).to eq 2
      end
    end

    it 'handles list with inline formatting' do
      html = '<ul><li>[ ] <b>Task</b></li></ul>'
      result = filter(html)

      input = result.at_css('li input')
      expect(input).to be_present
      expect(input['class']).to eq 'task-list-item-checkbox'
      expect(result.at_css('li b')).to be_present
    end

    it 'converts empty checkbox marker' do
      result = filter('<ul><li>[ ]</li></ul>')

      expect(result.at_css('li input')).to be_present
      expect(result.at_css('li')['class']).to eq 'task-list-item'
      expect(result.at_css('ul')['class']).to eq 'task-list'
    end
  end

  describe 'does not convert non-checkbox items' do
    using RSpec::Parameterized::TableSyntax

    where(:case_name, :html) do
      [
        ['missing space after checkbox bracket', '<ul><li>[ ]Task</li></ul>'],
        ['lowercase x marker', '<ul><li>[x] Task</li></ul>'],
        ['inapplicable marker', '<ul><li>[~] Task</li></ul>'],
        ['marker not at start', '<ul><li>Prefix [X] Task</li></ul>'],
        ['inline code', '<ul><li><code>[ ]</code> Task</li></ul>'],
        ['plain li without marker', '<ul><li>Task</li></ul>']
      ]
    end

    with_them do
      it 'does not convert' do
        result = filter(html)

        expect(result.at_css('li input')).not_to be_present
      end
    end
  end

  describe 'handles items with existing classes' do
    it 'skips li with existing class' do
      html = '<ul><li class="already-styled">[ ] Task</li></ul>'
      result = filter(html)

      li = result.at_css('li')
      expect(li['class']).to eq 'already-styled'
      expect(li.at_css('input')).to be_nil
    end

    using RSpec::Parameterized::TableSyntax

    where(:list_tag) do
      [['ul'], ['ol']]
    end

    with_them do
      it 'preserves existing class on parent' do
        html = "<#{list_tag} class=\"already-styled\"><li>[ ] Task</li></#{list_tag}>"
        result = filter(html)

        expect(result.at_css(list_tag)['class']).to eq 'already-styled'
        expect(result.at_css('li')['class']).to eq 'task-list-item'
        expect(result.at_css('li input')).to be_present
      end
    end
  end

  it_behaves_like 'limits the number of filtered items' do
    let(:text) do
      "<ul>#{'<li>[ ] Task</li>' * 3}</ul>"
    end

    let(:ends_with) { '</ul>' }
  end

  it_behaves_like 'pipeline timing check'
end
