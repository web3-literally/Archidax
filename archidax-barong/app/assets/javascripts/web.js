//= require rails-ujs
//= require jquery3
//= require popper
//= require bootstrap-sprockets
//= require bootstrap-datepicker
//= require dropify/src/js/dropify

//= require main

window.onload = function () {
  $('.datepicker-toggle').datepicker();

  $('#send-code-btn').on('click', function () {
    $('.loader').css("display", "block");
    $('#send-code-btn').hide();
    number = $("#country_code").val() + $("#number").val();
    $.ajax({
      headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
      method:  'POST',
      data:    { number: number },
      url:     '/users/phones/verification',
      success: function(result){
         if (result.success){
           $('.loader').css("display", "none");
           $('#send-code-btn').show();
           $("#error").text('');
           $("#create-phone").prop('disabled', false);
           $("#send-code-btn").text('Resend');
         } else {
           $('.loader').css("display", "none");
           $('#send-code-btn').show();
           $("#error").text(result.error);
         }
      }
    });
  });

  $('.dropify').dropify({
      tpl: {
          message:  '<div class="dropify-message"> <p>{{ default }}</p> </div>',
      }
  });

  $('#terms-agree-label').on('click', function(){
    if ($('#terms-agree').is(':checked')) {
      $('#terms-agree').attr('checked', false);
    } else {
      $('#terms-agree').attr('checked', true);
    }
  })

  if (location.href.includes('sing_up')) {
    $('#new_account input[type="submit"]').on('click', function(e){
      if (!$('#terms-agree').is(':checked')) {
        e.preventDefault();
        $('.error-checkbox').show();
      }
    })
  }
};
