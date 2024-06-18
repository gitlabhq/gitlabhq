# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Helpers::PaginationStrategies do
  subject { Class.new.include(described_class).new }

  let(:expected_result) { double("result") }
  let(:relation) { double("relation", klass: "SomeClass") }
  let(:params) { {} }

  before do
    allow(subject).to receive(:params).and_return(params)
  end

  describe '#paginate_with_strategies' do
    let(:paginator) { double("paginator", paginate: expected_result, finalize: nil) }

    before do
      allow(subject).to receive(:paginator).with(relation, nil).and_return(paginator)
    end

    it 'yields paginated relation' do
      expect { |b| subject.paginate_with_strategies(relation, nil, &b) }.to yield_with_args(expected_result)
    end

    it 'calls #finalize with first value returned from block' do
      return_value = double
      expect(paginator).to receive(:finalize).with(return_value)

      subject.paginate_with_strategies(relation, nil) do |records|
        some_options = {}
        [return_value, some_options]
      end
    end

    it 'returns whatever the block returns' do
      return_value = [double, double]

      result = subject.paginate_with_strategies(relation, nil) do |records|
        return_value
      end

      expect(result).to eq(return_value)
    end

    context "with paginator_params" do
      it 'correctly passes multiple parameters' do
        expect(paginator).to receive(:paginate).with(relation, parameter_one: true, parameter_two: 'two')

        subject.paginate_with_strategies(relation, nil, paginator_params: { parameter_one: true, parameter_two: 'two' })
      end
    end
  end

  describe '#paginator' do
    context 'offset pagination' do
      let(:plan_limits) { Plan.default.actual_limits }
      let(:offset_limit) { plan_limits.offset_pagination_limit }
      let(:paginator) { double("paginator") }

      before do
        allow(subject).to receive(:keyset_pagination_enabled?).and_return(false)
      end

      context 'when keyset pagination is available and enforced for the relation' do
        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available_for_type?).and_return(true)
          allow(Gitlab::Pagination::CursorBasedKeyset).to receive(:enforced_for_type?).and_return(true)
        end

        context 'when a request scope is given' do
          let(:params) { { per_page: 100, page: (offset_limit / 100) + 1 } }
          let(:request_scope) { double("scope", actual_limits: plan_limits) }

          context 'when the scope limit is exceeded' do
            it 'renders a 405 error' do
              expect(subject).to receive(:error!).with(/maximum allowed offset/, 405)

              subject.paginator(relation, request_scope)
            end

            context 'when keyset pagination is not enforced' do
              before do
                allow(Gitlab::Pagination::CursorBasedKeyset).to receive(:enforced_for_type?).and_return(false)
              end

              it 'returns no errors' do
                expect(subject).not_to receive(:error!)

                subject.paginator(relation, request_scope)
              end
            end
          end

          context 'when the scope limit is not exceeded' do
            let(:params) { { per_page: 100, page: offset_limit / 100 } }

            it 'delegates to OffsetPagination' do
              expect(Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(paginator)

              expect(subject.paginator(relation, request_scope)).to eq(paginator)
            end
          end
        end

        context 'when a request scope is not given' do
          context 'when the default limits are exceeded' do
            let(:params) { { per_page: 100, page: (offset_limit / 100) + 1 } }

            it 'renders a 405 error' do
              expect(subject).to receive(:error!).with(/maximum allowed offset/, 405)

              subject.paginator(relation)
            end
          end

          context 'when the default limits are not exceeded' do
            let(:params) { { per_page: 100, page: offset_limit / 100 } }

            it 'delegates to OffsetPagination' do
              expect(Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(paginator)

              expect(subject.paginator(relation)).to eq(paginator)
            end
          end
        end
      end

      context 'when keyset pagination is not available for the relation' do
        let(:params) { { per_page: 100, page: (offset_limit / 100) + 1 } }

        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available_for_type?).and_return(false)
        end

        it 'delegates to OffsetPagination' do
          expect(Gitlab::Pagination::OffsetPagination).to receive(:new).with(subject).and_return(paginator)

          expect(subject.paginator(relation)).to eq(paginator)
        end
      end
    end

    context 'for keyset pagination' do
      let(:params) { { pagination: 'keyset' } }
      let(:request_context) { double('request context') }
      let(:pager) { double('pager') }

      before do
        allow(subject).to receive(:keyset_pagination_enabled?).and_return(true)
        allow(Gitlab::Pagination::Keyset::RequestContext).to receive(:new).with(subject).and_return(request_context)
      end

      context 'when keyset pagination is available' do
        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available?).and_return(true)
          allow(Gitlab::Pagination::Keyset::Pager).to receive(:new).with(request_context).and_return(pager)
        end

        it 'delegates to Pager' do
          expect(subject.paginator(relation)).to eq(pager)
        end
      end

      context 'when keyset pagination is not available' do
        before do
          allow(Gitlab::Pagination::Keyset).to receive(:available?).with(request_context, relation).and_return(false)
        end

        it 'renders a 501 error' do
          expect(subject).to receive(:error!).with(/not yet available/, 405)

          subject.paginator(relation)
        end
      end
    end
  end
end
