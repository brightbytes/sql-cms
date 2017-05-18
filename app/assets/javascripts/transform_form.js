$(function() {
  $('#transform_runner').on('change', function(e) {

    // var index = ['AutoLoad', 'CopyFrom', 'CopyTo', 'Unload'].indexOf($(this).val())
    var index = ['AutoLoad', 'CopyFrom', 'CopyTo'].indexOf($(this).val())

    $('#transform_s3_file_name_input').toggle(index != -1);

    $('#transform_params_yaml_input').toggle($(this).val() != 'RailsMigration');

    $('#transform_sql_input').toggle($(this).val() != 'AutoLoad');

  });

});
