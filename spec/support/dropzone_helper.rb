module DropzoneHelper
  # Provides a way to perform `attach_file` for a Dropzone-based file input
  #
  # This is accomplished by creating a standard HTML file input on the page,
  # performing `attach_file` on that field, and then triggering the appropriate
  # Dropzone events to perform the actual upload.
  #
  # This method waits for the upload to complete before returning.
  def dropzone_file(file_path)
    # Generate a fake file input that Capybara can attach to
    page.execute_script <<-JS.strip_heredoc
      var fakeFileInput = window.$('<input/>').attr(
        {id: 'fakeFileInput', type: 'file'}
      ).appendTo('body');

      window._dropzoneComplete = false;
    JS

    # Attach the file to the fake input selector with Capybara
    attach_file('fakeFileInput', file_path)

    # Manually trigger a Dropzone "drop" event with the fake input's file list
    page.execute_script <<-JS.strip_heredoc
      var fileList = [$('#fakeFileInput')[0].files[0]];
      var e = jQuery.Event('drop', { dataTransfer : { files : fileList } });

      var dropzone = $('.div-dropzone')[0].dropzone;
      dropzone.on('queuecomplete', function() {
        window._dropzoneComplete = true;
      });
      dropzone.listeners[0].events.drop(e);
    JS

    # Wait until Dropzone's fired `queuecomplete`
    loop until page.evaluate_script('window._dropzoneComplete === true')
  end
end
