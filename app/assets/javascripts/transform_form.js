$(function() {
  $('#transform_runner').on('change', function(e) {

    $('#transform_params_yaml_input').toggle($(this).val() != 'RailsMigration');

    var indexName = ['DefaultCopyFrom', 'DefaultCopyTo'].indexOf($(this).val())
    $('#transform_name_input').toggle(indexName === -1);

    var indexSql = ['AutoLoad', 'DefaultCopyFrom', 'DefaultCopyTo'].indexOf($(this).val())
    $('#transform_sql_input').toggle(indexSql === -1);

    // var index = ['AutoLoad', 'CopyFrom', 'CopyTo', 'Unload'].indexOf($(this).val())
    var indexS3File = ['AutoLoad', 'CopyFrom', 'CopyTo', 'Unload'].indexOf($(this).val())
    $('#transform_s3_file_name_input').toggle(indexS3File !== -1);

  });

});
