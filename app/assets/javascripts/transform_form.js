$(function() {
  $('#transform_runner').on('change', function(e) {

    var importing = ($(this).val() == 'AutoLoad' || $(this).val() == 'CopyFrom');

    $('#transform_specify_s3_file_by_input').toggle(importing);
    $('#transform_supplied_s3_url_input').toggle(importing);

    // var exporting = ($(this).val() == 'Unload' || $(this).val() == 'CopyTo');
    var exporting = ($(this).val() == 'CopyTo');

    $('#transform_s3_file_path_input').toggle(exporting);
    $('#transform_s3_file_name_input').toggle(exporting);

    $('#transform_params_yaml_input').toggle($(this).val() != 'RailsMigration');

  });

  $('#transform_specify_s3_file_by').on('change', function(e) {

    var by_url = ($(this).val() == 'url');

    $('#transform_supplied_s3_url_input').toggle(by_url);

    $('#transform_s3_file_path_input').toggle(!by_url);
    $('#transform_s3_file_name_input').toggle(!by_url);

  });
});
