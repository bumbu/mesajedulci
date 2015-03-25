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
$f3->set('coverImage', 'public/img/fb-cover.png');

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
		$f3->set('coverImage', 'imagine/'.$f3->get('PARAMS.message'));

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
			$f3->set('preloadedMessage', str_replace("\n", '\n', $message->message));
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

function toArray($object) {
  $array = array();
  foreach ($object as $key => $value) {
    if ($value instanceof StdClass) {
      $array[$key] = toArray($value);
    } else {
      $array[$key] = $value;
    }
  }
  return $array;
}

$symbols = array(
  '-' => 'symbol-minus'
, ',' => 'symbol-comma'
, '.' => 'symbol-dot'
, '+' => 'symbol-plus'
, '(' => 'symbol-left-parantheses'
, ')' => 'symbol-right-parantheses'
, '?' => 'symbol-question'
, '!' => 'symbol-exclamation'
, ':' => 'symbol-column'
, '*' => 'symbol-star'
, '=' => 'symbol-equal'
, '>' => 'symbol-bigger'
, '<' => 'symbol-smaller');

function getFontData($fontName){
	global $symbols;

	$jsonData = file_get_contents('./fonts-server.json');
	$json = json_decode($jsonData);
	$fontData = toArray($json->$fontName);
	// $fontData['']
	foreach($symbols as $symbol => $symbolAlias){
		if (isset($fontData[$symbolAlias])) {
			$fontData[$symbol] = $fontData[$symbolAlias];
			$fontData[$symbol]['image'] = $symbolAlias;
			unset($fontData[$symbolAlias]);
		}
	}

	$newFontData = array();

	foreach($fontData as $symbol => $symbolData) {
		if (!isset($symbolData['image'])) {
			$fontData[$symbol]['image'] = $symbol;
		}

		$newFontData[strtoupper($symbol)] = $fontData[$symbol];
	}

	return $newFontData;
}

define('IMAGE_FULL_WIDTH', 1200);
define('IMAGE_FULL_HEIGHT', 628);
define('IMAGE_TEXT_WIDTH',  floor(IMAGE_FULL_WIDTH * 0.8));
define('IMAGE_TEXT_HEIGHT', floor(IMAGE_FULL_HEIGHT * 0.8));
define('SYMBOL_HEIGHT', 120);

function mbStringToArray ($string) {
  $strlen = mb_strlen($string);
  while ($strlen) {
    $array[] = mb_substr($string,0,1,"UTF-8");
    $string = mb_substr($string,1,$strlen,"UTF-8");
    $strlen = mb_strlen($string);
  }
  return $array;
}

function getSymbolData($fontData, $symbol){
	$symbol = strtoupper($symbol);

	if ($symbol === ' '){
		return array(
			'width'=> floor(SYMBOL_HEIGHT / 3)
		, 'height'=> SYMBOL_HEIGHT
		, 'image'=> null
		);
	}	else if (isset($fontData[$symbol])){
		return $fontData[$symbol];
	} else {
		return $fontData['?'];
	}
}

function getStrWidth($fontData, $str){
	$width = 0;
	foreach(mbStringToArray($str) as $symbol){
		$symbolData = getSymbolData($fontData, $symbol);
		$width += $symbolData['width'];
	}

	return $width;
}

function getImage($fontData, $fontName, $message){
	$rows = explode("\n", $message);
	$totalWidth = 0;
	$totalHeight = 0;

	foreach($rows as $row){
		$width = getStrWidth($fontData, $row);
		$totalWidth = max($totalWidth, $width);
		$totalHeight += SYMBOL_HEIGHT;
	}

	$bigImage = new Image('./public/img/fb-cover-bg.png');
	$bigImage->resize($totalWidth, $totalHeight);

	$heigthOffset = 0;
	foreach($rows as $row){
		$width = getStrWidth($fontData, $row);

		$rowImage = new Image('./public/img/fb-cover-bg.png');
		$rowImage->resize($width, SYMBOL_HEIGHT);

		// Add symbols
		$widthOffset = 0;
		foreach(mbStringToArray($row) as $index => $symbol){
			$symbolData = getSymbolData($fontData, $symbol);

			if (isset($symbolData['image'])) {
				$symbolImage = new Image('./public/fonts/'.$fontName.'/'.$symbolData['image'].'.jpg');
				$rowImage->overlay($symbolImage, array($widthOffset, 0));
				unset($symbolImage);
			}

			$widthOffset += $symbolData['width'];
		}

		// Overlay this image over big image
		$bigImage->overlay($rowImage, array(floor(($totalWidth-$width)/2), $heigthOffset));
		$heigthOffset += SYMBOL_HEIGHT;

		// Delete row image
		unset($rowImage);

	}

	// Resize big image max text size
	$bigImage->resize(IMAGE_TEXT_WIDTH, IMAGE_TEXT_HEIGHT, false, false);

	$coverImage = new Image('./public/img/fb-cover-bg.png');

	// Fit into cover
	$coverImage->overlay($bigImage, array(floor((IMAGE_FULL_WIDTH - $bigImage->width())/2), floor((IMAGE_FULL_HEIGHT - $bigImage->height())/2)));

	return $coverImage;
}

$normalizeChars = array(
    'Š'=>'S', 'š'=>'s', 'Ð'=>'Dj','Ž'=>'Z', 'ž'=>'z', 'À'=>'A', 'Á'=>'A', 'Â'=>'A', 'Ã'=>'A', 'Ä'=>'A',
    'Å'=>'A', 'Æ'=>'A', 'Ç'=>'C', 'È'=>'E', 'É'=>'E', 'Ê'=>'E', 'Ë'=>'E', 'Ì'=>'I', 'Í'=>'I', 'Î'=>'I',
    'Ï'=>'I', 'Ñ'=>'N', 'Ò'=>'O', 'Ó'=>'O', 'Ô'=>'O', 'Õ'=>'O', 'Ö'=>'O', 'Ø'=>'O', 'Ù'=>'U', 'Ú'=>'U',
    'Û'=>'U', 'Ü'=>'U', 'Ý'=>'Y', 'Þ'=>'B', 'ß'=>'Ss','à'=>'a', 'á'=>'a', 'â'=>'a', 'ã'=>'a', 'ä'=>'a',
    'å'=>'a', 'æ'=>'a', 'ç'=>'c', 'è'=>'e', 'é'=>'e', 'ê'=>'e', 'ë'=>'e', 'ì'=>'i', 'í'=>'i', 'î'=>'i',
    'ï'=>'i', 'ð'=>'o', 'ñ'=>'n', 'ò'=>'o', 'ó'=>'o', 'ô'=>'o', 'õ'=>'o', 'ö'=>'o', 'ø'=>'o', 'ù'=>'u',
    'ú'=>'u', 'û'=>'u', 'ý'=>'y', 'ý'=>'y', 'þ'=>'b', 'ÿ'=>'y', 'ƒ'=>'f',
    'ă'=>'a', 'î'=>'i', 'â'=>'a', 'ș'=>'s', 'ț'=>'t', 'Ă'=>'A', 'Î'=>'I', 'Â'=>'A', 'Ș'=>'S', 'Ț'=>'T',
);

$f3->route('GET /imagine/@message',
	function($f3) {
		global $normalizeChars;

		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');
		$message->load(array('@_id=?', $f3->get('PARAMS.message')));

		if($message->dry()){
			$img = new Image('public/img/fb-cover.png');
			$img->render();
		} else {
			// load symbols data
			$fontData = getFontData($message->font);
			$messageText = strtr($message->message, $normalizeChars);
			$image = getImage($fontData, $message->font, $messageText);
			$image->render();
		}
	}
);

$f3->run();
