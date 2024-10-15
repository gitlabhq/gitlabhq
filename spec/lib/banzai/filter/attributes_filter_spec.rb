# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AttributesFilter, feature_category: :markdown do
  using RSpec::Parameterized::TableSyntax
  include FilterSpecHelper

  def image
    %(<img src="example.jpg">)
  end

  describe 'attribute syntax' do
    context 'when attribute syntax is valid' do
      where(:text, :result) do
        "#{image}{width=100}"           | '<img src="example.jpg" width="100">'
        "#{image}{  width=100 }"        | '<img src="example.jpg" width="100">'
        "#{image}{width=\"100\"}"       | '<img src="example.jpg" width="100">'
        "#{image}{width=100 width=200}" | '<img src="example.jpg" width="200">'

        "#{image}{.test_class width=100 style=\"width:400\"}"   | '<img src="example.jpg" width="100">'
        "<img src=\"example.jpg\" class=\"lazy\" />{width=100}" | '<img src="example.jpg" class="lazy" width="100">'
      end

      with_them do
        it 'adds them to the img' do
          expect(filter(text).to_html).to eq result
        end
      end
    end

    context 'when attribute syntax is invalid' do
      where(:text, :result) do
        "#{image} {width=100}"             | '<img src="example.jpg"> {width=100}'
        "#{image}{width=100\nheight=100}"  | "<img src=\"example.jpg\">{width=100\nheight=100}"
        "{width=100 height=100}\n#{image}" | "{width=100 height=100}\n<img src=\"example.jpg\">"
        '<h1>header</h1>{width=100}'       | '<h1>header</h1>{width=100}'
      end

      with_them do
        it 'does not recognize as attributes' do
          expect(filter(text).to_html).to eq result
        end
      end
    end
  end

  describe 'height and width' do
    context 'when size attributes are valid' do
      where(:text, :result) do
        "#{image}{width=100 height=200px}" | '<img src="example.jpg" width="100" height="200px">'
        "#{image}{width=100}"              | '<img src="example.jpg" width="100">'
        "#{image}{width=100px}"            | '<img src="example.jpg" width="100px">'
        "#{image}{height=100%}"            | '<img src="example.jpg" height="100%">'
        "#{image}{width=\"100%\"}"         | '<img src="example.jpg" width="100%">'
      end

      with_them do
        it 'adds them to the img' do
          expect(filter(text).to_html).to eq result
        end
      end
    end

    context 'when size attributes are invalid' do
      where(:text, :result) do
        "#{image}{width=100cs}"           | '<img src="example.jpg">'
        "#{image}{width=auto height=200}" | '<img src="example.jpg" height="200">'
        "#{image}{width=10000}"           | '<img src="example.jpg">'
        "#{image}{width=-200}"            | '<img src="example.jpg">'
      end

      with_them do
        it 'ignores them' do
          expect(filter(text).to_html).to eq result
        end
      end
    end
  end

  it_behaves_like 'pipeline timing check'
end
