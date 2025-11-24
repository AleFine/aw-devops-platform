<?php
header('Content-Type: text/plain');
$counterFile = '/tmp/requests_total';
if (!file_exists($counterFile)) {
    file_put_contents($counterFile, '0');
}
$fh = fopen($counterFile, 'c+');
if ($fh) {
    flock($fh, LOCK_EX);
    $countData = stream_get_contents($fh);
    $count = (int)trim($countData);
    $count++;
    ftruncate($fh, 0);
    rewind($fh);
    fwrite($fh, (string)$count);
    flock($fh, LOCK_UN);
    fclose($fh);
} else {
    $count = 0;
}
// Basic metrics
echo "bootcamp_requests_total {$count}\n";
echo "bootcamp_last_request_timestamp " . time() . "\n";
?>
