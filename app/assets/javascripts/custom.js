// All application-wide custom code

$(function () {
	initialize();

	// Infinite scrolling
	if($('#infinite-scrolling').size() > 0) {
		$(window).on('scroll', function(e) {
			more_url = $('.pagination .next_page a').attr('href');
			if(more_url && $(window).scrollTop() > $(document).height() - $(window).height() - 180) {
				$('.pagination').html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />');
            	$.getScript(more_url);
			}
		});
		$(window).scroll(); // Triggers it at page load in case it's not below the fold
	}

	// Opens the first email thread on page load
	if($('#results').find('[data-role="thread-email-link"]').length > 0) {
		$('#results').find('[data-role="thread-email-link"]').first().click();
	}
});

// All JS that should also be available even after we load content via ajax in a modal
function initialize() {
	// Activate tooltip
	$('[data-toggle="tooltip"]').tooltip();

	// Toggle checkboxes when design elements clicked
	$('[data-action="toggle-checkbox"]').off('click').on('click', function(e) {
		e.preventDefault();
		e.stopPropagation();
		if($($(this).attr('data-target')).prop('checked')) {
			$($(this).attr('data-target')).prop('checked', false);
			$(this).find('[data-role="checkbox-indicator"]').addClass('inactive').removeClass('active');
		}
		else {
			$($(this).attr('data-target')).prop('checked', true);
			$(this).find('[data-role="checkbox-indicator"]').addClass('active').removeClass('inactive');
		}
		$($(this).attr('data-target')).closest('form').submit();

	});

	// Show / hide collapsed element when click on collapse trigger
	$('[data-role="collapse"]').off('click').on('click', function(e) {
		e.stopPropagation(); // prevents the click from bubbling and being picked up by parent events
		$($(this).attr('data-target')).toggleClass('hide');
	});

	// Hide all collapsable elements when trigger has data-expanded set as false
	$('[data-role="collapse"][data-expanded="false"]').each(function() {
		$($(this).attr('data-target')).addClass('hide');
	});

	// Toggle elements on click (hide the one clicked, show all others)
	$('[data-role="toggle-collapse"]').off('click').on('click', function(e) {
		e.preventDefault();
		$('[data-role="toggle-collapse"][data-id="' + $(this).attr('data-id') + '"]').show(); // show all those who have the same data-id
		$(this).hide(); // hide the one clicked
	});

	// Hide the element clicked if it's a toggle trigger and show the recipients
	$('[data-role="trigger-collapse"]').off('click').on('click', function(e) {
		e.preventDefault();
		$('[data-role="receive-collapse"][data-id="' + $(this).attr('data-id') + '"]').show(); // show all those who have the same data-id
		$(this).hide(); // hide the one clicked
	});

	// Toggle the display of an element when a trigger is clicked (without hiding the trigger)
	$('[data-role="trigger-toggle-display"]').off('click').on('click', function(e) {
		e.preventDefault();
		$($(this).attr('data-target')).toggleClass('hide');
	});

	// Calls the email thread via ajax
	$('[data-role="thread-email-link"]').off('click').on('click', function(e) {
		$('#emails').html('<img src="../assets/ajax-monster.gif" class="center-block" />');
		$('#emails').load($(this).attr('data-path'), function() {
			initialize();
			download_inline_attachments();
		});
	});

	// Handle floating alert messages
  if($('#server-notice').length) {
    BootstrapAlert.success({
      message: $('#server-notice').html()
    });
  }
  if($('#server-alert').length) {
    BootstrapAlert.alert({
      message: $('#server-alert').html()
    });
  }
  if($('#shutdown-announcement').length) {
    BootstrapAlert.alert({
      message: $('#shutdown-announcement').html(),
      autoHide: false,
      dissmissible: true
    });
  }
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
		if(download_url) {
			$.getScript(download_url);
		}
	});
}
