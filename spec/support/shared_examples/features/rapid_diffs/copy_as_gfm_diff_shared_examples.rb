# frozen_string_literal: true

# Copy-as-GFM from a Rapid Diffs text diff: selecting diff lines copies the expected GFM.
# The including spec must define `visit_rapid_diff(view:)` to open a Rapid Diffs page in the
# given view ('inline' or 'parallel') showing the popen.rb change from the `feature` branch.
RSpec.shared_examples 'copy as GFM from a Rapid Diffs diff' do
  include ActionView::Helpers::JavaScriptHelper

  let(:added_raise_row) { 'line_2f6fcd96b_A9' }
  let(:removed_raise_row) { 'line_2f6fcd96b_9' }
  let(:unless_row) { 'line_2f6fcd96b_8' }
  let(:end_row) { 'line_2f6fcd96b_10' }

  # rubocop:disable RSpec/NoExpectationExample -- assertions live in the `verify` helper
  context 'with the inline view' do
    before do
      visit_rapid_diff(view: 'inline')
    end

    it 'copies a single word as inline code' do
      verify(
        "##{added_raise_row} .line .no",
        '`RuntimeError`',
        target: "##{added_raise_row}"
      )
    end

    it 'copies a single line as inline code' do
      verify(
        "##{added_raise_row} .line",
        '`      raise RuntimeError, "System commands must be given as an array of strings"`',
        target: "##{added_raise_row}"
      )
    end

    it 'copies multiple lines as a code block' do
      verify(
        "##{added_raise_row} .line, ##{end_row} .line",
        <<~GFM,
          ```ruby
                raise RuntimeError, "System commands must be given as an array of strings"
              end
          ```
        GFM
        target: "##{added_raise_row}"
      )
    end
  end

  context 'with the parallel view' do
    before do
      visit_rapid_diff(view: 'parallel')
    end

    let(:rows_selector) { "##{unless_row}, ##{removed_raise_row}, ##{added_raise_row}, ##{end_row}" }

    it 'copies code on the old (left) side as a code block' do
      verify(
        rows_selector,
        <<~GFM,
          ```ruby
              unless cmd.is_a?(Array)
                raise "System commands must be given as an array of strings"
              end
          ```
        GFM
        target: "##{unless_row} td[data-position='old']"
      )
    end

    it 'copies code on the new (right) side as a code block' do
      verify(
        rows_selector,
        <<~GFM,
          ```ruby
              unless cmd.is_a?(Array)
                raise RuntimeError, "System commands must be given as an array of strings"
              end
          ```
        GFM
        target: "##{unless_row} td[data-position='new']"
      )
    end
  end
  # rubocop:enable RSpec/NoExpectationExample

  def verify(selector, gfm, target: nil)
    expect(page).to have_selector('.line')
    html = html_for_selector(selector)
    output_gfm = html_to_gfm(html, 'transformCodeSelection', target: target)
    wait_for_requests # rubocop:disable RSpec/AvoidWaitForRequests -- ensures the async clipboard transform settled
    expect(output_gfm.strip).to eq(gfm.strip)
  end

  def html_for_selector(selector)
    js = <<~JS
      (function(selector) {
        var els = document.querySelectorAll(selector);
        var htmls = [].slice.call(els).map(function(el) { return el.outerHTML; });
        return htmls.join("\\n");
      })("#{escape_javascript(selector)}")
    JS
    page.evaluate_script(js)
  end

  def html_to_gfm(html, transformer = 'transformGFMSelection', target: nil)
    js = <<~JS
      (function(html) {
        // Setting it off so the import already starts
        window.CopyAsGFM.nodeToGFM(document.createElement('div'));

        var transformer = window.CopyAsGFM[#{transformer.inspect}];

        var node = document.createElement('div');
        $(html).each(function() { node.appendChild(this) });

        var targetSelector = #{target.to_json};
        var target;
        if (targetSelector) {
          target = document.querySelector(targetSelector);
        }

        node = transformer(node, target);
        if (!node) return null;


        window.gfmCopytestRes = null;
        window.CopyAsGFM.nodeToGFM(node)
        .then((res) => {
          window.gfmCopytestRes = res;
        });
      })("#{escape_javascript(html)}")
    JS
    page.execute_script(js)

    loop until page.evaluate_script('window.gfmCopytestRes !== null')

    page.evaluate_script('window.gfmCopytestRes')
  end
end
