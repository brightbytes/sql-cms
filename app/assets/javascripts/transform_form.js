$(function(){
  $('#transform_runner').on('change', function(e){
    $('#transform_supplied_s3_url_input').toggle($(this).val() == 'AutoLoad' || $(this).val() == 'CopyFrom');
    $('#transform_s3_region_name_input').toggle($(this).val() == 'Unload' || $(this).val() == 'CopyTo');
    $('#transform_s3_bucket_name_input').toggle($(this).val() == 'Unload' || $(this).val() == 'CopyTo');
    $('#transform_s3_file_path_input').toggle($(this).val() == 'Unload' || $(this).val() == 'CopyTo');
    $('#transform_s3_file_name_input').toggle($(this).val() == 'Unload' || $(this).val() == 'CopyTo');
  });
});
