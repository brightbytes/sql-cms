$(function(){
  $('#data_file_file_type').on('change', function(e){
    $('#data_file_supplied_s3_url_input').toggle($(this).val() == 'import');
    $('#data_file_s3_region_name_input').toggle($(this).val() == 'export');
    $('#data_file_s3_bucket_name_input').toggle($(this).val() == 'export');
    $('#data_file_s3_file_path_input').toggle($(this).val() == 'export');
    $('#data_file_s3_file_name_input').toggle($(this).val() == 'export');
  });
});
