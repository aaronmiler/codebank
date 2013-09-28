$("#new_wisdom").validate({
  rules: {
      title: "required",
      topic: "required",
      contents: "required",
  },
  submitHandler: function(form) {
    form.submit();
  },
  errorClass:'has-error',
  highlight: function (element, errorClass, validClass) { 
    $(element).parents("div.form-group").addClass(errorClass);

  }, 
  unhighlight: function (element, errorClass, validClass) { 
    $(element).parents(".has-error").removeClass(errorClass);
  },
  errorPlacement: function(error,element) {
    return false;
  }, 
  // showErrors: function(errorMap, errorList) {
  //   $("#alert").append('<div class="alert alert-danger" style="display:none"> <button type="button" class="close" data-dismiss="alert" aria-hidden="true">×</button> <strong>Missing Required Fields</strong> Please make sure all fields highlighted in red are filled out </div>')
  //   $(".alert").slideDown(function(){
  //     $(this).delay(3000).slideUp(function(){
  //       $(this).remove()
  //     })
  //   });
  // }
});