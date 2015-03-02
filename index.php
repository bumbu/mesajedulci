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

$f3->route('GET /',
	function($f3) {
		$f3->set('footer','footer-editor.html');
		echo View::instance()->render('layout.html');
	}
);

$f3->route('GET /distribuie/@message',
	function($f3) {
		$f3->set('footer','footer-share.html');
		echo View::instance()->render('layout.html');
	}
);

$f3->route('GET /mesaj/@message',
	function($f3) {
		$f3->set('footer','footer-shared.html');
		echo View::instance()->render('layout.html');
	}
);

$f3->run();
