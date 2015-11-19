$(function () {
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
