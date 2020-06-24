# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::CoverageReports do
  let(:coverage_report) { described_class.new }

  it { expect(coverage_report.files).to eq({}) }

  describe '#pick' do
    before do
      coverage_report.add_file('app.rb', { 1 => 0, 2 => 1 })
      coverage_report.add_file('routes.rb', { 3 => 1, 4 => 0 })
    end

    it 'returns only picked files while ignoring nonexistent ones' do
      expect(coverage_report.pick(['routes.rb', 'nonexistent.txt'])).to eq({
        files: { 'routes.rb' => { 3 => 1, 4 => 0 } }
      })
    end
  end

  describe '#add_file' do
    context 'when providing two individual files' do
      before do
        coverage_report.add_file('app.rb', { 1 => 0, 2 => 1 })
        coverage_report.add_file('routes.rb', { 3 => 1, 4 => 0 })
      end

      it 'initializes a new test suite and returns it' do
        expect(coverage_report.files).to eq({
          'app.rb' => { 1 => 0, 2 => 1 },
          'routes.rb' => { 3 => 1, 4 => 0 }
        })
      end
    end

    context 'when providing the same files twice' do
      context 'with different line coverage' do
        before do
          coverage_report.add_file('admin.rb', { 1 => 0, 2 => 1 })
          coverage_report.add_file('admin.rb', { 3 => 1, 4 => 0 })
        end

        it 'initializes a new test suite and returns it' do
          expect(coverage_report.files).to eq({
            'admin.rb' => { 1 => 0, 2 => 1, 3 => 1, 4 => 0 }
          })
        end
      end

      context 'with identical line coverage' do
        before do
          coverage_report.add_file('projects.rb', { 1 => 0, 2 => 1 })
          coverage_report.add_file('projects.rb', { 1 => 0, 2 => 1 })
        end

        it 'initializes a new test suite and returns it' do
          expect(coverage_report.files).to eq({
            'projects.rb' => { 1 => 0, 2 => 2 }
          })
        end
      end
    end
  end
end
