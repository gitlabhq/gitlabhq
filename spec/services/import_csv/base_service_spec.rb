# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportCsv::BaseService, feature_category: :importers do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:csv_io) { double }

  subject { described_class.new(user, project, csv_io) }

  shared_examples 'abstract method' do |method, args|
    it "raises NotImplemented error when #{method} is called" do
      if args
        expect { subject.send(method, args) }.to raise_error(NotImplementedError)
      else
        expect { subject.send(method) }.to raise_error(NotImplementedError)
      end
    end
  end

  it_behaves_like 'abstract method', :email_results_to_user
  it_behaves_like 'abstract method', :attributes_for, "any"
  it_behaves_like 'abstract method', :validate_headers_presence!, "any"
  it_behaves_like 'abstract method', :create_object_class

  describe '#detect_col_sep' do
    context 'when header contains invalid separators' do
      it 'raises error' do
        header = 'Name&email'

        expect { subject.send(:detect_col_sep, header) }.to raise_error(CSV::MalformedCSVError)
      end
    end

    context 'when header is valid' do
      shared_examples 'header with valid separators' do
        let(:header) { "Name#{separator}email" }

        it 'returns separator value' do
          expect(subject.send(:detect_col_sep, header)).to eq(separator)
        end
      end

      context 'with ; as separator' do
        let(:separator) { ';' }

        it_behaves_like 'header with valid separators'
      end

      context 'with \t as separator' do
        let(:separator) { "\t" }

        it_behaves_like 'header with valid separators'
      end

      context 'with , as separator' do
        let(:separator) { ',' }

        it_behaves_like 'header with valid separators'
      end
    end
  end
end
