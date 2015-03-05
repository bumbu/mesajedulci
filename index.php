<?php
// PHP FatFREE 3.4

// Kickstart the framework
$f3=require('lib/base.php');

$f3->set('DEBUG',1);
if ((float)PCRE_VERSION<7.9)
	trigger_error('PCRE version is out of date');

// Load configuration
$f3->config('config.ini');

$f3->set('uriRoot', '/mesajedulci/');
$f3->set('fontsFile','js/fonts.json');
$f3->set('preloadedFont', 1);

$f3->set('footerShared','footer-shared.html');
$f3->set('footerEditor','footer-editor.html');
$f3->set('footerShare','footer-share.html');

$f3->route('GET /',
	function($f3) {
		$f3->set('preloadedFooter', 1);
		echo View::instance()->render('layout.html');
	}
);

$f3->route('GET /mesaj/@message',
	function($f3) {
		// If my message show share
		// If shared with me, show try by yourself
		$f3->set('preloadedFooter', 2);
		echo View::instance()->render('layout.html');
	}
);

$f3->run();
