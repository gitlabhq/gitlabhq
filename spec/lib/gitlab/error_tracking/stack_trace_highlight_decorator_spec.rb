# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ErrorTracking::StackTraceHighlightDecorator do
  let(:error_event) { build(:error_tracking_error_event) }

  describe '.decorate' do
    subject(:decorate) { described_class.decorate(error_event) }

    it 'does not change issue_id' do
      expect(decorate.issue_id).to eq(error_event.issue_id)
    end

    it 'does not change date_received' do
      expect(decorate.date_received).to eq(error_event.date_received)
    end

    it 'decorates the stack trace context' do
      expect(decorate.stack_trace_entries).to eq(
        [
          {
            'function' => 'puts',
            'lineNo' => 14,
            'filename' => 'hello_world.rb',
            'context' => [
              [10, '<span id="LC1" class="line" lang="ruby"><span class="c1"># Ruby example</span></span>'],
              [11, '<span id="LC1" class="line" lang="ruby"><span class="k">class</span> <span class="nc">HelloWorld</span></span>'],
              [12, '<span id="LC1" class="line" lang="ruby">  <span class="k">def</span> <span class="nc">self</span><span class="o">.</span><span class="nf">message</span></span>'],
              [13, '<span id="LC1" class="line" lang="ruby">    <span class="vi">@name</span> <span class="o">=</span> <span class="s1">\'World\'</span></span>'],
              [14, %Q[<span id="LC1" class="line" lang="ruby">    <span class="nb">puts</span> <span class="s2">"Hello </span><span class="si">\#{</span><span class="vi">@name</span><span class="si">}</span><span class="s2">"</span></span>]],
              [15, '<span id="LC1" class="line" lang="ruby">  <span class="k">end</span></span>'],
              [16, '<span id="LC1" class="line" lang="ruby"><span class="k">end</span></span>']
            ]
          },
          {
            'function' => 'print',
            'lineNo' => 6,
            'filename' => 'HelloWorld.swift',
            'context' => [
              [1, '<span id="LC1" class="line" lang="swift"><span class="c1">// Swift example</span></span>'],
              [2, '<span id="LC1" class="line" lang="swift"><span class="kd">struct</span> <span class="kt">HelloWorld</span> <span class="p">{</span></span>'],
              [3, '<span id="LC1" class="line" lang="swift">    <span class="k">let</span> <span class="nv">name</span> <span class="o">=</span> <span class="s">"World"</span></span>'],
              [4, '<span id="LC1" class="line" lang="swift"></span>'],
              [5, '<span id="LC1" class="line" lang="swift">    <span class="kd">static</span> <span class="kd">func</span> <span class="nf">message</span><span class="p">()</span> <span class="p">{</span></span>'],
              [6, '<span id="LC1" class="line" lang="swift">        <span class="nf">print</span><span class="p">(</span><span class="s">"Hello, </span><span class="se">\\(</span><span class="k">self</span><span class="o">.</span><span class="n">name</span><span class="se">)</span><span class="s">"</span><span class="p">)</span></span>'],
              [7, '<span id="LC1" class="line" lang="swift">    <span class="p">}</span></span>'],
              [8, '<span id="LC1" class="line" lang="swift"><span class="p">}</span></span>']
            ]
          },
          {
            'filename' => 'blank.txt'
          }
        ]
      )
    end
  end
end
