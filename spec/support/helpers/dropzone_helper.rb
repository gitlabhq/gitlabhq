# frozen_string_literal: true

module DropzoneHelper
  # Provides a way to perform `attach_file` for a Dropzone-based file input
  #
  # This is accomplished by creating a standard HTML file input on the page,
  # performing `attach_file` on that field, and then triggering the appropriate
  # Dropzone events to perform the actual upload.
  #
  # This method waits for the upload to complete before returning.
  # max_file_size is an optional parameter.
  # If it's not 0, then it used in dropzone.maxFilesize parameter.
  # wait_for_queuecomplete is an optional parameter.
  # If it's 'false', then the helper will NOT wait for backend response
  # It lets to test behaviors while AJAX is processing.
  def dropzone_file(files, max_file_size = 0, wait_for_queuecomplete = true)
    # Generate a fake file input that Capybara can attach to
    page.execute_script <<-JS.strip_heredoc
      $('#fakeFileInput').remove();
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file', multiple: true}
      ).appendTo('body');

      window._dropzoneComplete = false;
    JS

    # Attach files to the fake input selector with Capybara
    attach_file('fakeFileInput', files)

    first('.div-dropzone')

    # Manually trigger a Dropzone "drop" event with the fake input's file list
    page.execute_script <<-JS.strip_heredoc
      var dropzone = $('.div-dropzone')[0].dropzone;
      dropzone.options.autoProcessQueue = false;

      if (#{max_file_size} > 0) {
        dropzone.options.maxFilesize = #{max_file_size};
      }

      dropzone.on('queuecomplete', function() {
        window._dropzoneComplete = true;
      });

      var fileList = [$('#fakeFileInput')[0].files];

      $.map(fileList, function(file){
        var e = jQuery.Event('drop', { dataTransfer : { files : file } });

        dropzone.listeners[0].events.drop(e);
      });

      dropzone.processQueue();
    JS

    if wait_for_queuecomplete
      # Wait until Dropzone's fired `queuecomplete`
      loop until page.evaluate_script('window._dropzoneComplete === true')
    end
  end

  def drop_in_dropzone(file_path)
    # Generate a fake input selector
    page.execute_script <<-JS
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file'}
      ).appendTo('body');
    JS

    # Attach the file to the fake input selector with Capybara
    attach_file('fakeFileInput', file_path)

    # Add the file to a fileList array and trigger the fake drop event
    page.execute_script <<-JS
      var fileList = [$('#fakeFileInput')[0].files[0]];
      var e = jQuery.Event('drop', { dataTransfer : { files : fileList } });
      $('.dropzone')[0].dropzone.listeners[0].events.drop(e);
    JS
  end
end
