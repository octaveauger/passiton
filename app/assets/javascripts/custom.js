// All application-wide custom code

$(function () {
	// Toggle checkboxes when design elements clicked
	$('[data-action="toggle-checkbox"]').on('click', function(e) {
		e.preventDefault();
		$('#' + $(this).attr('data-target')).trigger('click');
		if($('#' + $(this).attr('data-target')).prop('checked')) {
			$(this).find('[data-role="checkbox-indicator"]').addClass('active').removeClass('inactive');
		}
		else {
			$(this).find('[data-role="checkbox-indicator"]').addClass('inactive').removeClass('active');
		}
	});

	// Activate tooltip
	$('[data-toggle="tooltip"]').tooltip();
});
