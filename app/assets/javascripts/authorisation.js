$(function () {
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

	// Highlight / Un-highlight a thread
	$('input.checkbox-highlight').on('change', function(e) {
		$(this).parents('form.form-highlight').submit();
	});

	// Auto-refresh authorisations status (synced / granted or not)
	autorefresh_authorisations_index();
});

function autorefresh_authorisations_index() {
	if($('.refresh-authorisation-status').size() > 0) {
		setTimeout(function() {
			$.getScript($('#result').attr('data-target'));
			autorefresh_authorisations_index(); // create loop
		}, 10000); // every 10s
		
	}
}