echo "<h1>aw-bootcamp Day 4</h1>";
echo "<p>Aplicación de Kevin corriendo en contenedor</p>";
echo "<p>Hostname: " . gethostname() . "</p>";
<?php
$counterFile = '/tmp/requests_total';
$tsFile = '/tmp/last_request_ts';
if (!file_exists($counterFile)) {
	file_put_contents($counterFile, '0');
}
$fh = fopen($counterFile, 'c+');
if ($fh) {
	flock($fh, LOCK_EX);
	$current = (int)trim(stream_get_contents($fh));
	$current++;
	ftruncate($fh, 0);
	rewind($fh);
	fwrite($fh, (string)$current);
	flock($fh, LOCK_UN);
	fclose($fh);
}
file_put_contents($tsFile, (string)time(), LOCK_EX);

echo "<h1>aw-bootcamp App</h1>";
echo "<p>Aplicación de Kevin corriendo en contenedor</p>";
echo "<p>Hostname: " . htmlspecialchars(gethostname()) . "</p>";
echo "<p>Total requests (aprox): " . (int)trim(file_get_contents($counterFile)) . "</p>";
// Minimal environment info
echo "<pre>PHP Version: " . PHP_VERSION . "\n";
echo "Loaded Extensions: " . implode(', ', get_loaded_extensions()) . "</pre>";
