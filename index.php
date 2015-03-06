<?php
// PHP FatFREE 3.4

// Kickstart the framework
$f3=require('lib/base.php');

$f3->set('DEBUG',1);
if ((float)PCRE_VERSION<7.9)
	trigger_error('PCRE version is out of date');

// Load configuration
$f3->config('config.ini');

$f3->set('fontsFile','js/fonts.json');
$f3->set('preloadedFont', 1);

$f3->set('footerShared','footer-shared.html');
$f3->set('footerEditor','footer-editor.html');
$f3->set('footerShare','footer-share.html');
$f3->set('preloadedMessage', '');

header('Access-Control-Allow-Origin: static.ak.facebook.com');

$f3->route('GET /',
	function($f3) {
		$f3->set('preloadedFooter', 1);
		echo View::instance()->render('layout.html');
	}
);

$f3->route('GET /mesaj/@message',
	function($f3) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');
		$message->load(array('@_id=?', $f3->get('PARAMS.message')));

		$f3->set('messageId', $f3->get('PARAMS.message'));

		if($message->dry()){
			// Nothing found, redirect to main page
			$f3->set('preloadedFooter', 1);
		} else {
			// If my message show share
			if ($f3->get('SESSION.author') === $message->author) {
				$f3->set('preloadedFooter', 2);
			// If shared with me, show try by yourself
			} else {
				$f3->set('preloadedFooter', 0);
			}

			$f3->set('preloadedFont', $message->font[strlen($message->font) - 1]);
			$f3->set('preloadedFrom', $message->from);
			$f3->set('preloadedTo', $message->to);
			$f3->set('preloadedMessage', substr(json_encode($message->message), 1, -1));
		}
		echo View::instance()->render('layout.html');
	}
);

$f3->route('POST /mesaj',
	function($f3, $params) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');

		if (!$f3->get('SESSION.author')) {
			$f3->set('SESSION.author', uniqid());
		}

		$message->message = mb_substr($_POST['message'], 0, 200);
		$message->from = mb_substr($_POST['from'], 0, 30);
		$message->to = mb_substr($_POST['to'], 0, 30);
		$message->font = $_POST['font'];
		$message->author = $f3->get('SESSION.author');
		$message->save();

		echo json_encode(array('url' => $f3->get('URI_ROOT').'mesaj/'.$message->_id));
	}
);

$f3->route('POST /trimite',
	function($f3, $params) {
		// Trimite email
		sleep(1);

		// TODO validate email
		$email = $_POST['email'];
		if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
			echo json_encode(array('success'=>false));
			return;
		}

		$messageId = $_POST['messageId'];
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');
		$message->load(array('@_id=?', $messageId));

		if($message->dry()){
			// Nothing found, redirect to main page
			echo json_encode(array('success'=>false));
		} else {
			if($message->from)
				$subject = "Subject: Mesaj Dulce de la " . $message->from;
			else
				$subject = "Subject: Mesaj Dulce";

			$url = $f3->get('URI_ROOT').'mesaj/'.$messageId;

			$emailText = '
<html>
<head>
   <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
   <title>'.$subject.'</title>
</head>
<body>
  <p>Ai primit un mesaj dulce'.($message->from ? ' de la '.$message->from : '').'.</p>
  <p>Mesajul te așteaptă <a href="'.$url.'">pe adresa '.$url.'</a></p>
</body>
</html>
			';

			$headers   = array();
			$headers[] = "MIME-Version: 1.0";
			$headers[] = "Content-type: text/html; charset=utf-8";
			if ($message->from)
				$headers[] = "From: Mesaje Dulci (".$message->from.") <no-reply@mesajedulci.md>";
			else
				$headers[] = "From: Mesaje Dulci <no-reply@mesajedulci.md>";
			$headers[] = "Reply-To: Mesaje Dulci <no-reply@mesajedulci.md>";
			$headers[] = "Subject: ".$subject;
			$headers[] = "X-Mailer: PHP/".phpversion();

			mail($email, $subject, $emailText, implode("\r\n", $headers));

			echo json_encode(array('success'=>true));
		}
	}
);

$f3->run();
