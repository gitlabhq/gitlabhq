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

  context 'when given a class' do
    let(:importer_klass) do
      Class.new(described_class) do
        def attributes_for(row)
          { title: row[:title] }
        end

        def validate_headers_presence!(headers)
          raise CSV::MalformedCSVError.new("Missing required headers", 1) unless headers.present?
        end

        def create_object_class
          Class.new
        end

        def email_results_to_user
          # no-op
        end
      end
    end

    let(:service) do
      uploader = FileUploader.new(project)
      uploader.store!(file)

      importer_klass.new(user, project, uploader)
    end

    subject { service.execute }

    it_behaves_like 'correctly handles invalid files'

    describe '#detect_col_sep' do
      using RSpec::Parameterized::TableSyntax

      let(:file) { double }

      before do
        allow(service).to receive_message_chain('csv_data.lines.first').and_return(header)
      end

      where(:sep_character, :valid) do
        '&' | false
        '?' | false
        ';' | true
        ',' | true
        "\t" | true
      end

      with_them do
        let(:header) { "Name#{sep_character}email" }

        it 'responds appropriately' do
          if valid
            expect(service.send(:detect_col_sep)).to eq sep_character
          else
            expect { service.send(:detect_col_sep) }.to raise_error(CSV::MalformedCSVError)
          end
        end
      end
    end
  end
end
