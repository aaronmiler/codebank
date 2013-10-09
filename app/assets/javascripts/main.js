$(".simple_form.wisdom").validate({
  rules: {
      "wisdom[title]": "required",
      "wisdom[topic]": "required",
      "wisdom[contents]": "required"
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
  }
});
$('#topics').mCustomScrollbar({
  mouseWheel:true,
  set_width: true,
  theme: "light-thick"
})