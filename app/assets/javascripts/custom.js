// All application-wide custom code

$(function () {
	initialize();
});

// All JS that should also be available even after we load content via ajax in a modal
function initialize() {
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

	// Toggle elements on click (hide the one clicked, show all others)
    $('[data-role="toggle-collapse"]').click(function(e) {
      $('[data-role="toggle-collapse"][data-id="' + $(this).attr('data-id') + '"]').show(); // show all those who have the same data-id
      $(this).hide(); // hide the one clicked
    });

    // Calls the email thread modal via ajax
	$('.modal-link[data-role="thread-modal-link"]').on('click', function(e) {
		$('#' + $(this).attr('data-target')).find('.modal-content').load($(this).attr('data-path'), function(){
			initialize();
			download_inline_attachments();
		});
		$('#' + $(this).attr('data-target')).modal('show');
	});
}

// Download and replace inline attachments via Ajax
function download_inline_attachments() {
	// Create a non unique list of content ids to download
	var duplicate_list = [];
	$('img[src^="cid:"]').each(function(e) {
		duplicate_list.push($(this).attr('src').replace('cid:', ''));
	});

	// De-duplicate the list of content ids to download
	var unique = {}
	var unique_list = []	
	duplicate_list.forEach(function(x) {
		if(!unique[x]) {
			unique_list.push(x);
			unique[x] = true;
		}
	});

	// Call the inline attachment download
	unique_list.forEach(function(a) {
		var download_url = $('img[src^="cid:' + a + '"]').attr('data-target');
		$.getScript(download_url);
	});
}