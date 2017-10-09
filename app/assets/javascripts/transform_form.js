$(function() {
  $('#transform_runner').on('change', function(e) {

    $('#transform_params_yaml_input').toggle($(this).val() !== 'RailsMigration');

    $('#transform_sql_input').toggle($(this).val() !== 'AutoLoad');

    var indexS3File = ['AutoLoad', 'CopyFrom', 'CopyTo', 'Unload'].indexOf($(this).val())
    $('#transform_s3_file_name_input').toggle(indexS3File !== -1);

  });

});
