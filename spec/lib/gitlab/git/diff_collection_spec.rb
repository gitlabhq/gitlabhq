# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::DiffCollection, feature_category: :source_code_management do
  before do
    stub_const('MutatingConstantIterator', Class.new)

    MutatingConstantIterator.class_eval do
      include Enumerable

      attr_reader :size

      def initialize(count, value)
        @count = count
        @size  = count
        @value = value
      end

      def each
        return enum_for(:each) unless block_given?

        loop do
          break if @count == 0

          # It is critical to decrement before yielding. We may never reach the lines after 'yield'.
          @count -= 1
          yield @value
        end
      end
    end
  end

  let(:overflow_max_bytes) { false }
  let(:overflow_max_files) { false }
  let(:overflow_max_lines) { false }

  shared_examples 'overflow stuff' do
    it 'returns the expected overflow values' do
      subject.overflow?
      expect(subject.overflow_max_bytes?).to eq(overflow_max_bytes)
      expect(subject.overflow_max_files?).to eq(overflow_max_files)
      expect(subject.overflow_max_lines?).to eq(overflow_max_lines)
    end
  end

  subject do
    described_class.new(
      iterator,
      max_files: max_files,
      max_lines: max_lines,
      limits: limits,
      expanded: expanded
    )
  end

  let(:iterator) { MutatingConstantIterator.new(file_count, fake_diff(line_length, line_count)) }
  let(:file_count) { 0 }
  let(:line_length) { 1 }
  let(:line_count) { 1 }
  let(:max_files) { 10 }
  let(:max_lines) { 100 }
  let(:limits) { true }
  let(:expanded) { true }

  describe '#to_a' do
    subject { super().to_a }

    it { is_expected.to be_kind_of ::Array }
  end

  describe '#decorate!' do
    let(:file_count) { 3 }

    it 'modifies the array in place' do
      count = 0
      subject.decorate! { |d| !d.nil? && count += 1 }
      expect(subject.to_a).to eq([1, 2, 3])
      expect(count).to eq(3)
    end

    it 'avoids future iterator iterations' do
      subject.decorate! { |d| d unless d.nil? }

      expect(iterator).not_to receive(:each)

      subject.overflow?
    end
  end

  context 'overflow handling' do
    subject { super() }

    let(:collapsed_safe_files) { false }
    let(:collapsed_safe_lines) { false }

    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('3') }
        end

        describe '#size' do
          it { expect(subject.size).to eq(3) }

          it 'does not change after peeking' do
            subject.any?
            expect(subject.size).to eq(3)
          end
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq file_count * line_count }
        end

        context 'when limiting is disabled' do
          let(:limits) { false }
          let(:overflow_max_bytes) { false }
          let(:overflow_max_files) { false }
          let(:overflow_max_lines) { false }

          it_behaves_like 'overflow stuff'

          describe '#overflow?' do
            subject { super().overflow? }

            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }

            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }

            it { is_expected.to eq('3') }
          end

          describe '#size' do
            it { expect(subject.size).to eq(3) }

            it 'does not change after peeking' do
              subject.any?
              expect(subject.size).to eq(3)
            end
          end

          describe '#line_count' do
            subject { super().line_count }

            it { is_expected.to eq file_count * line_count }
          end
        end
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }
        let(:overflow_max_lines) { true }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('0+') }
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq 1000 }
        end

        it { expect(subject.size).to eq(0) }

        context 'when limiting is disabled' do
          let(:limits) { false }
          let(:overflow_max_bytes) { false }
          let(:overflow_max_files) { false }
          let(:overflow_max_lines) { false }

          it_behaves_like 'overflow stuff'

          describe '#overflow?' do
            subject { super().overflow? }

            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }

            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }

            it { is_expected.to eq('3') }
          end

          describe '#line_count' do
            subject { super().line_count }

            it { is_expected.to eq file_count * line_count }
          end

          it { expect(subject.size).to eq(3) }
        end
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }
      let(:overflow_max_files) { true }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('10+') }
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq 10 }
        end

        it { expect(subject.size).to eq(10) }

        context 'when limiting is disabled' do
          let(:limits) { false }
          let(:overflow_max_bytes) { false }
          let(:overflow_max_files) { false }
          let(:overflow_max_lines) { false }

          it_behaves_like 'overflow stuff'

          describe '#overflow?' do
            subject { super().overflow? }

            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }

            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }

            it { is_expected.to eq('11') }
          end

          describe '#line_count' do
            subject { super().line_count }

            it { is_expected.to eq file_count * line_count }
          end

          it { expect(subject.size).to eq(11) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 30 }
        let(:overflow_max_lines) { true }
        let(:overflow_max_files) { false }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('3+') }
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq 120 }
        end

        it { expect(subject.size).to eq(3) }

        context 'when limiting is disabled' do
          let(:limits) { false }
          let(:overflow_max_bytes) { false }
          let(:overflow_max_files) { false }
          let(:overflow_max_lines) { false }

          it_behaves_like 'overflow stuff'

          describe '#overflow?' do
            subject { super().overflow? }

            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }

            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }

            it { is_expected.to eq('11') }
          end

          describe '#line_count' do
            subject { super().line_count }

            it { is_expected.to eq file_count * line_count }
          end

          it { expect(subject.size).to eq(11) }
        end
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('10') }
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq file_count * line_count }
        end

        it { expect(subject.size).to eq(10) }
      end
    end

    context 'adding too many bytes' do
      let(:file_count) { 10 }
      let(:line_length) { 5200 }
      let(:overflow_max_bytes) { true }

      it_behaves_like 'overflow stuff'

      describe '#overflow?' do
        subject { super().overflow? }

        it { is_expected.to be_truthy }
      end

      describe '#empty?' do
        subject { super().empty? }

        it { is_expected.to be_falsey }
      end

      describe '#real_size' do
        subject { super().real_size }

        it { is_expected.to eq('9+') }
      end

      describe '#line_count' do
        subject { super().line_count }

        it { is_expected.to eq file_count * line_count }
      end

      it { expect(subject.size).to eq(9) }

      context 'when limiting is disabled' do
        let(:limits) { false }
        let(:overflow_max_bytes) { false }
        let(:overflow_max_files) { false }
        let(:overflow_max_lines) { false }

        it_behaves_like 'overflow stuff'

        describe '#overflow?' do
          subject { super().overflow? }

          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }

          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }

          it { is_expected.to eq('10') }
        end

        describe '#line_count' do
          subject { super().line_count }

          it { is_expected.to eq file_count * line_count }
        end

        it { expect(subject.size).to eq(10) }
      end
    end
  end

  describe 'empty collection' do
    subject { described_class.new([]) }

    it_behaves_like 'overflow stuff'

    describe '#overflow?' do
      subject { super().overflow? }

      it { is_expected.to be_falsey }
    end

    describe '#empty?' do
      subject { super().empty? }

      it { is_expected.to be_truthy }
    end

    describe '#size' do
      subject { super().size }

      it { is_expected.to eq(0) }
    end

    describe '#real_size' do
      subject { super().real_size }

      it { is_expected.to eq('0') }
    end

    describe '#line_count' do
      subject { super().line_count }

      it { is_expected.to eq 0 }
    end
  end

  describe '#each' do
    context 'with Gitlab::GitalyClient::DiffStitcher' do
      let(:offset_index) { 0 }
      let(:collection) do
        described_class.new(
          iterator,
          max_files: max_files,
          max_lines: max_lines,
          limits: limits,
          expanded: expanded,
          generated_files: generated_files,
          offset_index: offset_index
        )
      end

      let(:iterator) { Gitlab::GitalyClient::DiffStitcher.new(diff_params) }
      let(:diff_params) { [diff_1, diff_2, diff_3] }
      let(:diff_1) do
        OpenStruct.new(
          to_path: ".gitmodules",
          from_path: ".gitmodules",
          old_mode: 0100644,
          new_mode: 0100644,
          from_id: '357406f3075a57708d0163752905cc1576fceacc',
          to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
          patch: 'a' * 10,
          raw_patch_data: 'a' * 10,
          end_of_patch: true
        )
      end

      let(:diff_2) do
        OpenStruct.new(
          to_path: ".gitignore",
          from_path: ".gitignore",
          old_mode: 0100644,
          new_mode: 0100644,
          from_id: '357406f3075a57708d0163752905cc1576fceacc',
          to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
          patch: 'a' * 20,
          raw_patch_data: 'a' * 20,
          end_of_patch: true
        )
      end

      let(:diff_3) do
        OpenStruct.new(
          to_path: "README",
          from_path: "README",
          old_mode: 0100644,
          new_mode: 0100644,
          from_id: '357406f3075a57708d0163752905cc1576fceacc',
          to_id: '8e5177d718c561d36efde08bad36b43687ee6bf0',
          patch: 'a' * 100,
          raw_patch_data: 'a' * 100,
          end_of_patch: true
        )
      end

      context 'with generated_files' do
        let(:generated_files) { [diff_1.from_path] }

        it 'sets generated files as generated' do
          collection.each do |d|
            if d.old_path == diff_1.from_path
              expect(d.generated).to be true
            else
              expect(d.generated).to be false
            end
          end
        end

        describe '#empty?' do
          subject { collection.empty? }

          it { is_expected.to be_falsey }
        end
      end

      context 'without generated_files' do
        let(:generated_files) { nil }

        it 'set generated as nil' do
          collection.each do |d|
            expect(d.generated).to be_nil
          end
        end

        describe '#empty?' do
          subject { collection.empty? }

          it { is_expected.to be_falsey }
        end
      end

      context 'when offset_index is given' do
        let(:generated_files) { nil }

        context 'when offset_index is 0' do
          let(:offset_index) { 0 }

          it 'yields all diffs' do
            expect(collection.to_a.map(&:diff)).to eq(
              [
                diff_1.patch,
                diff_2.patch,
                diff_3.patch
              ]
            )
          end
        end

        context 'when offset index is 1' do
          let(:offset_index) { 1 }

          it 'does not yield diffs before the offset' do
            expect(collection.to_a.map(&:diff)).to eq(
              [
                diff_2.patch,
                diff_3.patch
              ]
            )
          end
        end

        context 'when offset_index is the same as the number of diffs' do
          let(:offset_index) { 3 }

          it 'yields no diffs' do
            expect(collection.to_a).to be_empty
          end
        end
      end
    end

    context 'with existing generated value in the hash' do
      let(:collection) do
        described_class.new([{ diff: 'some content', generated: true }])
      end

      it 'sets the diff as generated' do
        collection.each do |diff|
          expect(diff.generated).to eq true
        end
      end
    end

    context 'when diff are too large' do
      let(:collection) do
        described_class.new([{ diff: 'a' * 204800 }])
      end

      it 'yields Diff instances even when they are too large' do
        expect { |b| collection.each(&b) }
          .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
      end

      it 'prunes diffs that are too large' do
        diff = nil

        collection.each do |d|
          diff = d
        end

        expect(diff.diff).to eq('')
      end
    end

    context 'when diff is quite large will collapse by default' do
      let(:iterator) { [{ diff: 'a' * 20480 }] }

      context 'when no collapse is set' do
        let(:expanded) { true }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        it 'does not prune diffs' do
          diff = nil

          subject.each do |d|
            diff = d
          end

          expect(diff.diff).not_to eq('')
        end
      end

      context 'when no collapse is unset' do
        let(:expanded) { false }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        context 'single-file collections' do
          it 'does not prune diffs' do
            diff = nil

            subject.each do |d|
              diff = d
            end

            expect(diff.diff).not_to eq('')
          end
        end

        context 'multi-file collections' do
          let(:iterator) { [{ diff: 'b' }, { diff: 'a' * 20480 }] }

          it 'prunes diffs that are quite big' do
            diff = nil

            subject.each do |d|
              diff = d
            end

            expect(diff.diff).to eq('')
          end
        end

        context 'when go over safe limits on files' do
          let(:iterator) { [fake_diff(1, 1)] * 4 }

          before do
            allow(described_class)
              .to receive(:default_limits)
              .and_return({ max_files: 2, max_lines: max_lines })
          end

          it 'prunes diffs by default even little ones and sets collapsed_safe_files true' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # 90 lines
                expect(d.diff).to eq('')
              end
            end

            expect(subject.collapsed_safe_files?).to eq(true)
          end
        end

        context 'when go over safe limits on lines' do
          let(:iterator) do
            [
              fake_diff(1, 45),
              fake_diff(1, 45),
              fake_diff(1, 20480),
              fake_diff(1, 1)
            ]
          end

          before do
            allow(described_class)
              .to receive(:default_limits)
              .and_return({ max_files: max_files, max_lines: 80 })
          end

          it 'prunes diffs by default even little ones and sets collapsed_safe_lines true' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # 90 lines
                expect(d.diff).to eq('')
              end
            end

            expect(subject.collapsed_safe_lines?).to eq(true)
          end
        end

        context 'when go over safe limits on bytes' do
          let(:iterator) do
            [
              fake_diff(5, 10),
              fake_diff(5000, 10),
              fake_diff(5, 10),
              fake_diff(5, 10)
            ]
          end

          before do
            allow(Gitlab::CurrentSettings).to receive(:diff_max_patch_bytes).and_return(1.megabyte)

            allow(described_class)
              .to receive(:default_limits)
              .and_return({ max_files: 4, max_lines: 3000 })
          end

          it 'prunes diffs by default even little ones and sets collapsed_safe_bytes true' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # > 80 bytes
                expect(d.diff).to eq('')
              end
            end

            expect(subject.collapsed_safe_bytes?).to eq(true)
          end
        end
      end

      context 'when limiting is disabled' do
        let(:limits) { false }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        it 'does not prune diffs' do
          diff = nil

          subject.each do |d|
            diff = d
          end

          expect(diff.diff).not_to eq('')
        end
      end
    end

    context 'when offset_index is given' do
      subject do
        described_class.new(
          iterator,
          max_files: max_files,
          max_lines: max_lines,
          limits: limits,
          offset_index: 2,
          expanded: expanded
        )
      end

      def diff(raw)
        raw['diff']
      end

      let(:iterator) do
        [
          fake_diff(1, 1),
          fake_diff(2, 2),
          fake_diff(3, 3),
          fake_diff(4, 4)
        ]
      end

      it 'does not yield diffs before the offset' do
        expect(subject.to_a.map(&:diff)).to eq(
          [
            diff(fake_diff(3, 3)),
            diff(fake_diff(4, 4))
          ]
        )
      end

      context 'when go over safe limits on bytes' do
        let(:iterator) do
          [
            fake_diff(1, 10), # 10
            fake_diff(1, 10), # 20
            fake_diff(1, 15), # 35
            fake_diff(1, 20), # 55
            fake_diff(1, 45), # 100 - limit hit
            fake_diff(1, 45),
            fake_diff(1, 20480),
            fake_diff(1, 1)
          ]
        end

        before do
          allow(described_class)
            .to receive(:default_limits)
            .and_return({ max_files: max_files, max_lines: 80 })
        end

        it 'considers size of diffs before the offset for prunning' do
          expect(subject.to_a.map(&:diff)).to eq(
            [
              diff(fake_diff(1, 15)),
              diff(fake_diff(1, 20))
            ]
          )
        end
      end
    end
  end

  describe '.limits' do
    let(:options) { {} }

    subject { described_class.limits(options) }

    context 'when options do not include max_patch_bytes_for_file_extension' do
      it 'sets max_patch_bytes_for_file_extension as empty' do
        expect(subject[:max_patch_bytes_for_file_extension]).to eq({})
      end
    end

    context 'when options include max_patch_bytes_for_file_extension' do
      let(:options) { { max_patch_bytes_for_file_extension: { '.file' => 1 } } }

      it 'sets value for max_patch_bytes_for_file_extension' do
        expect(subject[:max_patch_bytes_for_file_extension]).to eq({ '.file' => 1 })
      end
    end
  end

  def fake_diff(line_length, line_count)
    { 'diff' => "#{'a' * line_length}\n" * line_count }
  end
end
