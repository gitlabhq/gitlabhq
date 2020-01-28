# frozen_string_literal: true

# the idea of creating zip archive with spoofed size is borrowed from
# https://github.com/rubyzip/rubyzip/pull/403/files#diff-118213fb4baa6404a40f89e1147661ebR88
RSpec.shared_context 'pages zip with spoofed size' do
  let(:real_zip_path) { Tempfile.new(['real', '.zip']).path }
  let(:fake_zip_path) { Tempfile.new(['fake', '.zip']).path }

  before do
    full_file_name = 'public/index.html'
    true_size = 500_000
    fake_size = 1

    ::Zip::File.open(real_zip_path, ::Zip::File::CREATE) do |zf|
      zf.get_output_stream(full_file_name) do |os|
        os.write 'a' * true_size
      end
    end

    compressed_size = nil
    ::Zip::File.open(real_zip_path) do |zf|
      a_entry = zf.find_entry(full_file_name)
      compressed_size = a_entry.compressed_size
    end

    true_size_bytes = [compressed_size, true_size, full_file_name.size].pack('LLS')
    fake_size_bytes = [compressed_size, fake_size, full_file_name.size].pack('LLS')

    data = File.binread(real_zip_path)
    data.gsub! true_size_bytes, fake_size_bytes

    File.open(fake_zip_path, 'wb') do |file|
      file.write data
    end
  end

  after do
    File.delete(real_zip_path) if File.exist?(real_zip_path)
    File.delete(fake_zip_path) if File.exist?(fake_zip_path)
  end
end
