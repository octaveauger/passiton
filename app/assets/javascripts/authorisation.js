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
});