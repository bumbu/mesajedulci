<?php
// PHP FatFREE 3.4

// Kickstart the framework
$f3=require('lib/base.php');

$f3->set('DEBUG',1);
if ((float)PCRE_VERSION<7.9)
	trigger_error('PCRE version is out of date');

// Load configuration
$f3->config('config.ini');

// Detect language
$lang = 'ro';
if (isset($_COOKIE['lang'])) {
	$lang = $_COOKIE['lang'];
}
if (isset($_GET['lang'])) {
	$lang = $_GET['lang'];
	setcookie('lang', $lang,time() + (86400 * 365), '/'); // One year
}
if ($lang !== 'ro' && $lang !== 'ru') {
	$lang = 'ro';
}

$f3->set('lang', $lang);
$f3->set('LANGUAGE', $lang);

if ($lang === 'ro') {
	$font_first = 1;
	$font_last = 5;
} else if ($lang === 'ru') {
	$font_first = 6;
	$font_last = 7;
}

$f3->set('font_first', $font_first);
$f3->set('font_last', $font_last);

$f3->set('fontsFile','js/fonts.json');
$f3->set('preloadedFont', 1);

$f3->set('footerShared','footer-shared.html');
$f3->set('footerEditor','footer-editor.html');
$f3->set('footerShare','footer-share.html');
$f3->set('preloadedMessage', '');
$f3->set('coverImage', 'public/img/fb-cover.png');
$f3->set('mode', 'WRITE');

header('Access-Control-Allow-Origin: static.ak.facebook.com');

$f3->route('GET /',
	function($f3) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');


		$f3->set('messagesCount', $message->count());
		$f3->set('preloadedFooter', 1);
		$f3->set('preloadedFont', rand($f3->get('font_first'), $f3->get('font_last')));

		echo View::instance()->render('layout.html');
	}
);

$f3->route('GET /mesaj/@message',
	function($f3) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');
		$count = $message->count();
		$message->load(array('@_id=?', $f3->get('PARAMS.message')));

		$f3->set('messageId', $f3->get('PARAMS.message'));
		$f3->set('coverImage', 'imagine/'.$f3->get('PARAMS.message'));
		$f3->set('messagesCount', $count);
		$f3->set('mode', 'READ');

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

			$lang = 'ro';
			// Fix wrongly submited texts
			if ((isset($message->lang) && $message->lang === 'ru') || $message->font === 'font6' || $message->font === 'font7') {
				$lang = 'ru';
			}

			$f3->set('lang', $lang);
			$f3->set('LANGUAGE', $lang);
			setcookie('lang', $lang, time() + (86400 * 365), '/'); // One year
		}
		echo View::instance()->render('layout.html');
	}
);

$keys = array(
  array('doi', 'trei', 'patru', 'cinci', 'sase', 'sapte', 'opt', 'noua', 'zece', 'multi', 'saiseci.si.noua', 'mii.de.', 'o.oaste.de', 'milioane.de')
,	array('ursi', 'cerbi', 'cai', 'zmei', 'cucosi', 'iepuri', 'sarpi', 'lupi', 'motani', 'ciini', 'elefanti', 'vulturi', 'delfini', 'tigri')
, array('frumosi', 'viteji', 'uimiti', 'curiosi', 'creativi', 'jucausi', 'bosumflati', 'flaminzi', 'satui', 'somnorosi', 'agitati', 'gingasi', 'palizi', 'visatori')
, array('maninca', 'fac', 'cauta', 'privesc', 'strica', 'taie', 'picteaza', 'fotografiaza', 'uda', 'gatesc', 'miroase', 'asteapta', 'pindesc', 'asculta')
, array('carne', 'televizorul', 'casa', 'natura', 'patul', 'aerul', 'natura', 'timpul', 'cerul', 'copacii', 'marea', 'oceanul', 'pesti', 'pamint')
);

function getTextId($id){
	global $keys;
	$newIdPieces = [];

	$idBase14 = base_convert($id + 1, 10, 14);
	if (strlen($idBase14) < 5) {
		$idBase14 = str_repeat('0', 5 - strlen($idBase14)) . $idBase14;
	}

	for($i = 0; $i < 5; $i++){
		$index = intval(base_convert($idBase14[$i], 14, 10));
		$newIdPieces[] = $keys[$i][$index];
	}

	// If more than 4 characters then append the rest of them
	if (strlen($idBase14) > 5) {
		$newIdPieces[] = substr($idBase14, 5);
	}

	return implode('.', $newIdPieces);
}

$f3->route('POST /mesaj',
	function($f3, $params) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');

		if (!$f3->get('SESSION.author')) {
			$f3->set('SESSION.author', uniqid());
		}

		$from = $_POST['from'];
		$to = $_POST['to'];
		$font = $_POST['font'];
		// $from = $_POST['from'];

		$similarMessages = $message->find(array('@message=?',$_POST['message']));
		// Cast DB objects into array
		$similarMessages = array_map(function($m){return $m->cast();}, $similarMessages);
		// Filter
		$similarMessages = array_filter($similarMessages, function($m) use ($from){return $m['from'] == $from;});
		$similarMessages = array_filter($similarMessages, function($m) use ($to){return $m['to'] == $to;});
		$similarMessages = array_filter($similarMessages, function($m) use ($font){return $m['font'] == $font;});
		// Reset indexes
		$similarMessages = array_values($similarMessages);

		if (count($similarMessages) > 0){
			echo json_encode(array('url' => $f3->get('URI_ROOT').'mesaj/'.$similarMessages[0]['_id']));
		} else {
			// Detect the language by font
			$lang = 'ro';
			if ($_POST['font'] === 'font6' || $_POST['font'] === 'font7') {
				$lang = 'ru';
			}

			$message->message = mb_substr($_POST['message'], 0, 200);
			$message->from = mb_substr($_POST['from'], 0, 30);
			$message->to = mb_substr($_POST['to'], 0, 30);
			$message->font = $_POST['font'];
			$message->author = $f3->get('SESSION.author');
			$message->id = getTextId($message->count() + 1);
			$message->lang = $lang;
			$message->save();

			echo json_encode(array('url' => $f3->get('URI_ROOT').'mesaj/'.$message->_id));
		}

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

$symbols_ro = array(
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
, '<' => 'symbol-smaller'
, 'Ă' => 'accent-a-breve'
, 'Â' => 'accent-a-circumflex'
, 'Î' => 'accent-i-circumflex'
, 'Ș' => 'accent-s-comma'
, 'Ț' => 'accent-t-comma');

$symbols_ru = array(
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
, '<' => 'symbol-smaller'
, 'Б' => 'accent-b'
, 'Ю' => 'accent-iu'
, 'Ь' => 'accent-soft'
, 'Ч' => 'accent-ch'
, 'Ж' => 'accent-j'
, 'Ъ' => 'accent-strong'
, 'Д' => 'accent-d'
, 'К' => 'accent-k'
, 'Т' => 'accent-t'
, 'Е' => 'accent-e'
, 'Л' => 'accent-l'
, 'Ц' => 'accent-ts'
, 'Я' => 'accent-ea'
, 'М' => 'accent-m'
, 'У' => 'accent-u'
, 'Ё' => 'accent-eo'
, 'Н' => 'accent-n'
, 'В' => 'accent-v'
, 'Ф' => 'accent-f'
, 'О' => 'accent-o'
, 'З' => 'accent-z'
, 'Г' => 'accent-g'
, 'П' => 'accent-p'
, 'Х' => 'accent-h'
, 'Р' => 'accent-r'
, 'И' => 'accent-i'
, 'С' => 'accent-s'
, 'А' => 'accent-a'
, 'Й' => 'accent-i2'
, 'Ш' => 'accent-sh'
, 'Э' => 'accent-a2'
, 'Ы' => 'accent-i3'
, 'Щ' => 'accent-sh2'
);

function getFontData($fontName, $lang){
	global $symbols_ro, $symbols_ru;
	$symbols = $symbols_ro;
	if ($lang === 'ru') {
		$symbols = $symbols_ru;
	}

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
  $array = [];
  while ($strlen) {
    $array[] = mb_substr($string,0,1,"UTF-8");
    $string = mb_substr($string,1,$strlen,"UTF-8");
    $strlen = mb_strlen($string);
  }
  return $array;
}

function getSymbolData($fontData, $symbol){
	$symbol = mb_strtoupper($symbol);

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
		if (strlen($row) == 0) {
			$heigthOffset += SYMBOL_HEIGHT;
			continue;
		}
		$width = getStrWidth($fontData, $row);

		$rowImage = new Image('./public/img/fb-cover-bg.png');
		$rowImage->resize($width, SYMBOL_HEIGHT);

		// Add symbols
		$widthOffset = 0;
		foreach(mbStringToArray($row) as $index => $symbol){
			$symbolData = getSymbolData($fontData, $symbol);

			if (isset($symbolData['image'])) {
				$symbolImage = new Image('./public/fonts-server/'.$fontName.'/'.$symbolData['image'].'.jpg');
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
    'Š'=>'S', 'š'=>'s', 'Ð'=>'Dj','Ž'=>'Z', 'ž'=>'z', 'À'=>'Ă', 'Á'=>'Ă', 'Â'=>'Â', 'Ã'=>'Ă', 'Ä'=>'Ă',
    'Å'=>'Ă', 'Æ'=>'A', 'Ç'=>'C', 'È'=>'E', 'É'=>'E', 'Ê'=>'E', 'Ë'=>'E', 'Ì'=>'Î', 'Í'=>'Î', 'Î'=>'Î',
    'Ï'=>'Î', 'Ñ'=>'N', 'Ò'=>'O', 'Ó'=>'O', 'Ô'=>'O', 'Õ'=>'O', 'Ö'=>'O', 'Ø'=>'O', 'Ù'=>'U', 'Ú'=>'U',
    'Û'=>'U', 'Ü'=>'U', 'Ý'=>'Y', 'Þ'=>'B', 'ß'=>'Ss','à'=>'ă', 'á'=>'ă', 'â'=>'â', 'ã'=>'ă', 'ä'=>'ă',
    'å'=>'ă', 'æ'=>'a', 'ç'=>'c', 'è'=>'e', 'é'=>'e', 'ê'=>'e', 'ë'=>'e', 'ì'=>'î', 'í'=>'î', 'î'=>'î',
    'ï'=>'î', 'ð'=>'o', 'ñ'=>'n', 'ò'=>'o', 'ó'=>'o', 'ô'=>'o', 'õ'=>'o', 'ö'=>'o', 'ø'=>'o', 'ù'=>'u',
    'ú'=>'u', 'û'=>'u', 'ý'=>'y', 'ý'=>'y', 'þ'=>'b', 'ÿ'=>'y', 'ƒ'=>'f',
    'ă'=>'ă', 'î'=>'î', 'â'=>'â', 'ș'=>'ș', 'ț'=>'ț', 'Ă'=>'Ă', 'Î'=>'Î', 'Â'=>'Â', 'Ș'=>'Ș', 'Ț'=>'Ț',
    'ş'=>'ș', 'Ş'=>'Ș', 'ţ'=>'ț', 'Ţ'=>'Ț'
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
			$lang = 'ro';
			if (isset($message->lang) && $message->lang === 'ru') {
				$lang = 'ru';
			}
			$fontData = getFontData($message->font, $lang);
			$messageText = strtr($message->message, $normalizeChars);
			$image = getImage($fontData, $message->font, $messageText);
			$image->render();
		}
	}
);

$f3->route('GET /stats',
	function($f3, $params) {
		$db = new DB\Jig('db/data/', DB\Jig::FORMAT_JSON);
		$message = new DB\Jig\Mapper($db, 'message');
		$defaultMessage = "Alege-ți zahărul\nbrun preferat și\nscrie un mesaj\ndulce celor dragi!";

		echo 'Număr total de mesaje: '. count($message->find(array('@message!=?', $defaultMessage)));

		$nonDefaultMessages = $message->find(array('@message!=?',$defaultMessage));

		// echo '<br>Zahăr Bucăți: '.count($message->find(array('@font=?','font1')));
		echo '<br>Zahăr Bucăți: '.count(array_filter($nonDefaultMessages, function($a){return $a['font'] == 'font1';}));
		echo '<br>Zahăr Golden Granulated: '.count(array_filter($nonDefaultMessages, function($a){return $a['font'] == 'font2';}));
		echo '<br>Zahăr Demerara: '.count(array_filter($nonDefaultMessages, function($a){return $a['font'] == 'font3';}));
		echo '<br>Zahăr Pachețele: '.count(array_filter($nonDefaultMessages, function($a){return $a['font'] == 'font4';}));
		echo '<br>Zahăr brun din trestie de zahăr: '.count(array_filter($nonDefaultMessages, function($a){return $a['font'] == 'font5';}));

	}
);

$f3->run();
