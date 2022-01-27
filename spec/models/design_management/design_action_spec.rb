# frozen_string_literal: true
require 'spec_helper'

RSpec.describe DesignManagement::DesignAction do
  describe 'validations' do
    describe 'the design' do
      let(:fail_validation) { raise_error(/design/i) }

      it 'must not be nil' do
        expect { described_class.new(nil, :create, :foo) }.to fail_validation
      end
    end

    describe 'the action' do
      let(:fail_validation) { raise_error(/action/i) }

      it 'must not be nil' do
        expect { described_class.new(double, nil, :foo) }.to fail_validation
      end

      it 'must be a known action' do
        expect { described_class.new(double, :wibble, :foo) }.to fail_validation
      end
    end

    describe 'the content' do
      context 'content is necesary' do
        let(:fail_validation) { raise_error(/needs content/i) }

        %i[create update].each do |action|
          it "must not be nil if the action is #{action}" do
            expect { described_class.new(double, action, nil) }.to fail_validation
          end
        end
      end

      context 'content is forbidden' do
        let(:fail_validation) { raise_error(/forbids content/i) }

        it "must not be nil if the action is delete" do
          expect { described_class.new(double, :delete, :foo) }.to fail_validation
        end
      end
    end
  end

  describe '#gitaly_action' do
    let(:path) { 'some/path/somewhere' }
    let(:design) { double('path', full_path: path) }

    subject { described_class.new(design, action, content) }

    context 'the action needs content' do
      let(:action) { :create }
      let(:content) { :foo }

      it 'produces a good gitaly action' do
        expect(subject.gitaly_action).to eq(
          action: action,
          file_path: path,
          content: content
        )
      end
    end

    context 'the action forbids content' do
      let(:action) { :delete }
      let(:content) { nil }

      it 'produces a good gitaly action' do
        expect(subject.gitaly_action).to eq(action: action, file_path: path)
      end
    end
  end

  describe '#issue_id' do
    let(:issue_id) { :foo }
    let(:design) { double('id', issue_id: issue_id) }

    subject { described_class.new(design, :delete) }

    it 'delegates to the design' do
      expect(subject.issue_id).to eq(issue_id)
    end
  end

  describe '#performed' do
    let(:design) { double }

    subject { described_class.new(design, :delete) }

    it 'calls design#clear_version_cache when the action has been performed' do
      expect(design).to receive(:clear_version_cache)

      subject.performed
    end
  end
end
