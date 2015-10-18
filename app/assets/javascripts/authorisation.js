$(function () {
	// Infinite scrolling
	if($('#infinite-scrolling').size() > 0) {
		$(window).on('scroll', function(e) {
			more_url = $('.pagination .next_page a').attr('href');
			if(more_url && $(window).scrollTop() > $(document).height() - $(window).height() - 120) {
				$('.pagination').html('<img src="/assets/ajax-loader.gif" alt="Loading..." title="Loading..." />');
            	$.getScript(more_url);
			}
		});
	}
});